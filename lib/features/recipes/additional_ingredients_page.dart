import 'package:flutter/material.dart';

import '../../core/app_design.dart';
import '../../core/error_text.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/repositories/food_repository.dart';
import '../../data/models/food.dart';

class AdditionalIngredientsPage extends StatefulWidget {
  final String? mainChoice;
  final Set<String> initialSelectedFoodIds;
  final FoodRepository? repository;

  const AdditionalIngredientsPage({
    super.key,
    this.mainChoice,
    this.initialSelectedFoodIds = const <String>{},
    this.repository,
  });

  @override
  State<AdditionalIngredientsPage> createState() => _AdditionalIngredientsPageState();
}

class _AdditionalIngredientsPageState extends State<AdditionalIngredientsPage> {
  late final Set<String> selectedFoodIds = {...widget.initialSelectedFoodIds};

  Future<void> _openCategory(IngredientCategory category) async {
    final result = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => IngredientCategoryPage(
          category: category,
          initialSelectedFoodIds: selectedFoodIds,
          repository: widget.repository,
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

  void _finish() => Navigator.pop(context, selectedFoodIds);

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      extendBody: true,
      appBar: const TogetherAppBar(title: Text('Weitere Zutaten')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          children: [
            _CategoryCard(
              icon: Icons.rice_bowl_rounded,
              title: 'Beilage',
              subtitle: 'Reis, Nudeln oder Kartoffeln',
              onTap: () => _openCategory(IngredientCategory.side),
            ),
            const SizedBox(height: 12),
            _CategoryCard(
              icon: Icons.eco_rounded,
              title: 'Gemüse',
              subtitle: 'Frisches Gemüse für euer Rezept',
              onTap: () => _openCategory(IngredientCategory.vegetables),
            ),
            if (widget.mainChoice != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppDesign.secondarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant_menu_rounded, color: AppDesign.primaryDark),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hauptauswahl: ${widget.mainChoice}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (selectedFoodIds.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppDesign.secondarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppDesign.primaryDark),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${selectedFoodIds.length} Zutat${selectedFoodIds.length == 1 ? '' : 'en'} ausgewählt',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            onPressed: _finish,
            icon: const Icon(Icons.check_rounded),
            label: Text(
              selectedFoodIds.isEmpty
                  ? 'Ohne weitere Zutaten fortfahren'
                  : 'Auswahl übernehmen (${selectedFoodIds.length})',
            ),
          ),
        ),
      ),
    );
  }
}

enum IngredientCategory { side, vegetables, favorites }

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: AppDesign.secondarySurface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: AppDesign.primaryDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IngredientCategoryPage extends StatefulWidget {
  final IngredientCategory category;
  final Set<String> initialSelectedFoodIds;
  final FoodRepository? repository;

  const IngredientCategoryPage({
    super.key,
    required this.category,
    this.initialSelectedFoodIds = const <String>{},
    this.repository,
  });

  @override
  State<IngredientCategoryPage> createState() => _IngredientCategoryPageState();
}

class _IngredientCategoryPageState extends State<IngredientCategoryPage> {
  late final FoodRepository repository;
  late final Set<String> selectedFoodIds = {...widget.initialSelectedFoodIds};
  List<Food> foods = [];
  bool loading = true;
  String? error;

  String get title => switch (widget.category) {
        IngredientCategory.side => 'Beilage auswählen',
        IngredientCategory.vegetables => 'Gemüse auswählen',
        IngredientCategory.favorites => 'Favoriten auswählen',
      };

  String get subtitle => switch (widget.category) {
        IngredientCategory.side => 'Reis, Nudeln oder Kartoffeln',
        IngredientCategory.vegetables => 'Frisches Gemüse für euer Rezept',
        IngredientCategory.favorites => 'Eure bevorzugten Lebensmittel',
      };

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? FoodRepository();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await repository.foods();
      final preferences = widget.category == IngredientCategory.favorites
          ? await repository.preferences()
          : <String, String>{};
      if (!mounted) return;
      setState(() {
        foods = rows.where((food) => _matchesCategory(food, preferences)).toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = friendlyError(e);
      });
    }
  }

  bool _matchesCategory(Food food, Map<String, String> preferences) {
    final category = food.category.trim();
    final name = food.name.trim().toLowerCase();
    final isPotato = name.contains('kartoffel');
    final isRice = name.contains('reis');
    final isPasta = name.contains('nudel') || name.contains('pasta');

    return switch (widget.category) {
      // Beilage is intentionally narrow: only the three requested food groups.
      IngredientCategory.side => isRice || isPasta || isPotato,
      // The database category is authoritative for vegetables; potatoes are sides.
      IngredientCategory.vegetables => category == 'Gemüse' && !isPotato,
      // Favorites are independent of the food category.
      IngredientCategory.favorites => preferences[food.id] == 'like',
    };
  }

  void _toggle(String id) {
    setState(() {
      if (!selectedFoodIds.add(id)) selectedFoodIds.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return TogetherScaffold(
        backgroundType: TogetherBackgroundType.recipes,
        appBar: TogetherAppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      extendBody: true,
      appBar: TogetherAppBar(title: Text(title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 44),
                            const SizedBox(height: 12),
                            Text(error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Erneut laden'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : foods.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.category == IngredientCategory.favorites
                                      ? Icons.favorite_border_rounded
                                      : Icons.search_off_rounded,
                                  size: 46,
                                  color: AppDesign.secondaryText,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.category == IngredientCategory.favorites
                                      ? 'Noch keine Favoriten vorhanden.'
                                      : 'Keine passenden Lebensmittel gefunden.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          itemCount: foods.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final food = foods[index];
                            final id = food.id;
                            final name = food.name;
                            final checked = selectedFoodIds.contains(id);
                            return _FoodSelectionTile(
                              name: name,
                              checked: checked,
                              favorite: widget.category == IngredientCategory.favorites,
                              onTap: () => _toggle(id),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            onPressed: () => Navigator.pop(context, selectedFoodIds),
            icon: const Icon(Icons.check_rounded),
            label: Text(
              selectedFoodIds.isEmpty
                  ? 'Auswahl übernehmen'
                  : 'Auswahl übernehmen (${selectedFoodIds.length})',
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodSelectionTile extends StatelessWidget {
  final String name;
  final bool checked;
  final bool favorite;
  final VoidCallback onTap;

  const _FoodSelectionTile({
    required this.name,
    required this.checked,
    required this.favorite,
    required this.onTap,
  });

  IconData get _foodIcon {
    final value = name.toLowerCase();
    if (value.contains('reis')) return Icons.rice_bowl_rounded;
    if (value.contains('nudel') || value.contains('pasta')) return Icons.ramen_dining_rounded;
    if (value.contains('kartoffel')) return Icons.egg_alt_rounded;
    if (value.contains('brokkoli')) return Icons.eco_rounded;
    if (value.contains('karotte')) return Icons.grass_rounded;
    if (value.contains('tomate')) return Icons.local_florist_rounded;
    if (value.contains('zwiebel')) return Icons.circle_rounded;
    return favorite ? Icons.favorite_rounded : Icons.restaurant_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: checked,
      label: name,
      child: Material(
        color: checked ? AppDesign.secondarySurface : AppDesign.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppDesign.softSurface,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(_foodIcon, color: AppDesign.primaryDark, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(
                  checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  color: checked ? AppDesign.primary : AppDesign.secondaryText,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
