import 'package:flutter/material.dart';

import '../../core/app_design.dart';
import '../../core/error_text.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../core/services/food_choice_asset_service.dart';
import '../../core/food_mode.dart';
import '../../data/repositories/food_repository.dart';
import '../../data/models/food.dart';
import '../recipes/additional_ingredients_page.dart';
import '../recipes/saved_recipes_page.dart';
import '../recipes/add_recipe_page.dart';

/// Summary page after the main choice in "Wir kochen".
///
/// The selected main choice stays visible as the primary selection. Optional
/// ingredients are added through the existing V92 category flow and remain
/// selected when the user returns here.
class CookNextStepPage extends StatefulWidget {
  final String mainChoice;
  final DateTime? planDate;
  final VoidCallback? onNavigateToToday;
  final String? decisionRequestId;
  final FoodRepository? repository;
  final bool selectForToday;

  const CookNextStepPage({
    super.key,
    required this.mainChoice,
    this.planDate,
    this.onNavigateToToday,
    this.decisionRequestId,
    this.repository,
    this.selectForToday = true,
  });

  @override
  State<CookNextStepPage> createState() => _CookNextStepPageState();
}

class _CookNextStepPageState extends State<CookNextStepPage> {
  late final FoodRepository repository = widget.repository ?? FoodRepository();
  final Set<String> selectedFoodIds = <String>{};
  List<Food> foods = <Food>[];
  bool loadingFoods = true;
  String? foodLoadError;

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    try {
      final rows = await repository.foods();
      if (!mounted) return;
      setState(() {
        foods = rows;
        loadingFoods = false;
        foodLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadingFoods = false;
        foodLoadError = friendlyError(e);
      });
    }
  }

  Future<void> _openAdditionalIngredients() async {
    final result = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => AdditionalIngredientsPage(
          mainChoice: widget.mainChoice,
          initialSelectedFoodIds: selectedFoodIds,
          repository: repository,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      selectedFoodIds
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _findNewRecipes() async {
    final selected = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/cook/new-recipes'),
        builder: (_) => ChatGptRecipeSetupPage(
          initialMainChoice: widget.mainChoice,
          initialSelectedFoodIds: Set<String>.from(selectedFoodIds),
          decisionRequestId: widget.decisionRequestId,
          selectForToday: widget.selectForToday,
          autoOpenPrompt: true,
          planDate: widget.planDate,
        ),
      ),
    );
    if (selected == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _findSavedRecipes() async {
    final selected = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SavedRecipesPage(
          mainChoice: widget.mainChoice,
          selectedFoodIds: Set<String>.from(selectedFoodIds),
          decisionRequestId: widget.decisionRequestId,
          planDate: widget.planDate,
          onNavigateToToday: widget.onNavigateToToday,
        ),
      ),
    );
    if (selected == true && mounted) Navigator.pop(context, true);
  }

  List<Food> get selectedFoods => selectedFoodIds
      .map((id) => foods.where((food) => food.id == id).firstOrNull)
      .whereType<Food>()
      .toList();

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      appBar: TogetherAppBar(
        title: Text(widget.selectForToday ? 'Wir kochen' : 'Mit ChatGPT erstellen'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 28).clamp(0.0, double.infinity),
                      ),
                      child: _MyChoiceCard(
                        mainChoice: widget.mainChoice,
                        mainChoiceAsset: FoodChoiceAssetService.assetFor(FoodMode.cook, widget.mainChoice),
                        selectedFoods: selectedFoods,
                        loadingFoods: loadingFoods,
                        loadError: foodLoadError,
                        onAddIngredients: _openAdditionalIngredients,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!widget.selectForToday)
                _RecipeActionButton(
                  key: const Key('cook-summary-new-recipes'),
                  label: 'Neues Rezept suchen',
                  onPressed: _findNewRecipes,
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _RecipeActionButton(
                        key: const Key('cook-summary-new-recipes'),
                        label: 'Neues Rezept suchen',
                        onPressed: _findNewRecipes,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RecipeActionButton(
                        key: const Key('cook-summary-saved-recipes'),
                        label: 'Aus meinen Rezepten suchen',
                        onPressed: _findSavedRecipes,
                        secondary: true,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyChoiceCard extends StatelessWidget {
  final String mainChoice;
  final String? mainChoiceAsset;
  final List<Food> selectedFoods;
  final bool loadingFoods;
  final String? loadError;
  final VoidCallback onAddIngredients;

  const _MyChoiceCard({
    required this.mainChoice,
    required this.mainChoiceAsset,
    required this.selectedFoods,
    required this.loadingFoods,
    required this.loadError,
    required this.onAddIngredients,
  });

  List<Food> get _vegetableFoods => selectedFoods
      .where((food) => _isVegetable(food) && !_isPotato(food))
      .toList(growable: false);

  List<Food> get _sideFoods => selectedFoods
      .where(_isSideFood)
      .toList(growable: false);

  List<Food> get _otherFoods => selectedFoods
      .where((food) => !_isVegetable(food) && !_isPotato(food) && !_isSideFood(food))
      .toList(growable: false);

  bool _isVegetable(Food food) =>
      food.category.toLowerCase().contains('gemüse') ||
      food.category.toLowerCase().contains('vegetable');

  bool _isPotato(Food food) => food.name.toLowerCase().contains('kartoffel');

  bool _isSideFood(Food food) {
    final category = food.category.trim();
    final name = food.name.toLowerCase();
    if (['weisse bohne', 'weiße bohne', 'kidney bohne', 'grune bohne', 'grüne bohne', 'tortilla', 'toast']
        .any(name.contains)) return false;
    return name.contains('reis') || name.contains('nudel') || name.contains('pasta') ||
        name.contains('kartoffel') ||
        (category == 'Getreide & Beilagen' &&
            !['haferflocken', 'semmelbrösel'].any(name.contains)) ||
        category == 'Hülsenfrüchte' ||
        ['couscous', 'bulgur', 'quinoa', 'gnocchi', 'brot', 'baguette', 'toast', 'tortilla', 'bohne', 'linsen', 'kichererbse']
            .any(name.contains);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Meine Wahl',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _MainChoiceImage(assetPath: mainChoiceAsset),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    mainChoice,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _DottedSeparator(),
            if (loadingFoods) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 2),
            ] else if (loadError != null) ...[
              const SizedBox(height: 10),
              Text(loadError!, style: Theme.of(context).textTheme.bodySmall),
            ] else if (selectedFoods.isNotEmpty) ...[
              const SizedBox(height: 14),
              if (_vegetableFoods.isNotEmpty) ...[
                const _IngredientGroupHeading('Gemüse'),
                ..._vegetableFoods.map(
                  (food) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ChoiceRow(label: food.name),
                  ),
                ),
              ],
              if (_vegetableFoods.isNotEmpty && _sideFoods.isNotEmpty) ...[
                const SizedBox(height: 4),
                const Divider(height: 1),
                const SizedBox(height: 12),
              ],
              if (_sideFoods.isNotEmpty) ...[
                const _IngredientGroupHeading('Beilagen'),
                ..._sideFoods.map(
                  (food) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ChoiceRow(label: food.name),
                  ),
                ),
              ],
              if (_otherFoods.isNotEmpty) ...[
                if (_vegetableFoods.isNotEmpty || _sideFoods.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                ],
                const _IngredientGroupHeading('Sonstiges'),
                ..._otherFoods.map(
                  (food) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ChoiceRow(label: food.name),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 6),
            _AdditionalIngredientsAction(
              onTap: onAddIngredients,
            ),
          ],
        ),
      ),
    );
  }


}

class _IngredientGroupHeading extends StatelessWidget {
  final String title;

  const _IngredientGroupHeading(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _DottedSeparator extends StatelessWidget {
  const _DottedSeparator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      width: double.infinity,
      child: CustomPaint(
        painter: _DottedSeparatorPainter(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

class _DottedSeparatorPainter extends CustomPainter {
  final Color color;

  const _DottedSeparatorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    const diameter = 1.5;
    const spacing = 4.0;
    for (double x = diameter / 2; x < size.width; x += spacing) {
      canvas.drawCircle(Offset(x, size.height / 2), diameter / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DottedSeparatorPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MainChoiceImage extends StatelessWidget {
  final String? assetPath;

  const _MainChoiceImage({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppDesign.secondarySurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.restaurant_menu_rounded,
        size: 28,
        color: AppDesign.primaryDark,
      ),
    );

    if (assetPath == null) return fallback;

    return Semantics(
      image: true,
      label: 'Bild für die Auswahl',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Image.asset(
            assetPath!,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) => fallback,
          ),
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final String label;
  const _ChoiceRow({required this.label});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;
    return Padding(
      padding: const EdgeInsets.only(left: 14, top: 7, bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: textStyle?.copyWith(
                fontSize: (textStyle.fontSize ?? 16) * 0.92,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdditionalIngredientsAction extends StatelessWidget {
  final VoidCallback onTap;

  const _AdditionalIngredientsAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Weitere Zutaten hinzufügen',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline_rounded, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Weitere Zutaten hinzufügen',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool secondary;

  const _RecipeActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      backgroundColor: secondary ? AppDesign.surface : null,
      foregroundColor: secondary ? AppDesign.primaryDark : null,
      side: secondary ? const BorderSide(color: AppDesign.divider) : null,
      elevation: secondary ? 0 : null,
    );
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: style,
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Compatibility entry point kept for existing routes/tests. Recipe creation
/// now uses the external ChatGPT workflow and the stable JSON importer instead
/// of a paid OpenAI API call from the app.
class CookRecipeGenerationPage extends StatelessWidget {
  final String mainChoice;
  final String? decisionRequestId;
  final Set<String> selectedFoodIds;

  const CookRecipeGenerationPage({
    super.key,
    required this.mainChoice,
    this.decisionRequestId,
    this.selectedFoodIds = const <String>{},
  });

  @override
  Widget build(BuildContext context) {
    return ChatGptRecipeSetupPage(
      initialMainChoice: mainChoice,
      initialSelectedFoodIds: selectedFoodIds,
      decisionRequestId: decisionRequestId,
    );
  }
}
