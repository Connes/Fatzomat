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
  final String? decisionRequestId;
  final FoodRepository? repository;

  const CookNextStepPage({
    super.key,
    required this.mainChoice,
    this.planDate,
    this.decisionRequestId,
    this.repository,
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
          selectForToday: true,
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
      appBar: const TogetherAppBar(title: Text('Wir kochen')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            _MyChoiceCard(
              mainChoice: widget.mainChoice,
              mainChoiceAsset: FoodChoiceAssetService.assetFor(FoodMode.cook, widget.mainChoice),
              selectedFoods: selectedFoods,
              loadingFoods: loadingFoods,
              loadError: foodLoadError,
              onAddIngredients: _openAdditionalIngredients,
            ),
            const SizedBox(height: 20),
            _RecipeActionButton(
              key: const Key('cook-summary-new-recipes'),
              icon: Icons.auto_awesome_rounded,
              label: 'Neue Rezepte suchen',
              onPressed: _findNewRecipes,
            ),
            const SizedBox(height: 12),
            _RecipeActionButton(
              key: const Key('cook-summary-saved-recipes'),
              icon: Icons.menu_book_rounded,
              label: 'Aus meinen Rezepten suchen',
              onPressed: _findSavedRecipes,
              secondary: true,
            ),
          ],
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
            Center(
              child: Column(
                children: [
                  _MainChoiceImage(assetPath: mainChoiceAsset),
                  const SizedBox(height: 12),
                  Text(
                    mainChoice,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            if (loadingFoods) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 2),
            ] else if (loadError != null) ...[
              const SizedBox(height: 10),
              Text(loadError!, style: Theme.of(context).textTheme.bodySmall),
            ] else if (selectedFoods.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1),
              ),
              ...selectedFoods.map(
                (food) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ChoiceRow(
                    icon: _foodIcon(food.name),
                    label: food.name,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
            _AdditionalIngredientsAction(
              selectedCount: selectedFoods.length,
              onTap: onAddIngredients,
            ),
          ],
        ),
      ),
    );
  }

  static IconData _foodIcon(String name) {
    final value = name.toLowerCase();
    if (value.contains('reis')) return Icons.rice_bowl_rounded;
    if (value.contains('nudel') || value.contains('pasta')) return Icons.ramen_dining_rounded;
    if (value.contains('kartoffel')) return Icons.breakfast_dining_rounded;
    if (value.contains('brokkoli') || value.contains('salat') || value.contains('spinat')) return Icons.eco_rounded;
    if (value.contains('karotte') || value.contains('möhre')) return Icons.local_florist_rounded;
    return Icons.restaurant_rounded;
  }
}

class _MainChoiceImage extends StatelessWidget {
  final String? assetPath;

  const _MainChoiceImage({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        color: AppDesign.secondarySurface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Icon(
        Icons.restaurant_menu_rounded,
        size: 48,
        color: AppDesign.primaryDark,
      ),
    );

    if (assetPath == null) return fallback;

    return Semantics(
      image: true,
      label: 'Bild für die Auswahl',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: 128,
          height: 128,
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
  final IconData icon;
  final String label;
  const _ChoiceRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppDesign.secondarySurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 26, color: AppDesign.primaryDark),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _AdditionalIngredientsAction extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onTap;

  const _AdditionalIngredientsAction({required this.selectedCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final suffix = selectedCount == 0 ? '' : ' ($selectedCount ausgewählt)';
    return Semantics(
      button: true,
      label: 'Weitere Zutaten hinzufügen',
      child: Card(
        color: AppDesign.primarySoft,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.add_rounded, size: 28, color: AppDesign.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Weitere Zutaten hinzufügen$suffix',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppDesign.primaryDark,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool secondary;

  const _RecipeActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = secondary
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: AppDesign.surface,
              foregroundColor: AppDesign.primaryDark,
              side: const BorderSide(color: AppDesign.divider),
              elevation: 0,
            ),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          );
    return SizedBox(height: 56, child: button);
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
