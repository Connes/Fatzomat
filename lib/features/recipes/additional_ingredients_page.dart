import 'package:flutter/material.dart';

import '../../core/app_design.dart';
import '../../core/food_name_normalizer.dart';
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
  late final FoodRepository repository = widget.repository ?? FoodRepository();
  List<Food> foods = <Food>[];

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    try {
      final result = await repository.foods();
      if (!mounted) return;
      setState(() => foods = result);
    } catch (_) {
      // Keep the selection usable even if names cannot be loaded.
    }
  }

  List<Food> get selectedFoods => selectedFoodIds
      .map((id) => foods.where((food) => food.id == id).firstOrNull)
      .whereType<Food>()
      .toList(growable: false);

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
              title: 'Gemüse',
              subtitle: 'Frisches Gemüse für euer Rezept',
              onTap: () => _openCategory(IngredientCategory.vegetables),
            ),
            const SizedBox(height: 12),
            _CategoryCard(
              title: 'Beilagen',
              subtitle: 'Reis, Nudeln, Kartoffeln und mehr',
              onTap: () => _openCategory(IngredientCategory.side),
            ),
            const SizedBox(height: 12),
            _CategoryCard(
              title: 'Sonstiges',
              subtitle: 'Alle weiteren Lebensmittel',
              onTap: () => _openCategory(IngredientCategory.other),
            ),
            if (selectedFoodIds.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppDesign.secondarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppDesign.primaryDark),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ausgewählte Zutaten (${selectedFoodIds.length})',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    if (selectedFoods.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...selectedFoods.map(
                        (food) => Padding(
                          padding: const EdgeInsets.only(left: 36, bottom: 6),
                          child: Text('• ${food.name}'),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text('Zutaten werden geladen …'),
                    ],
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

enum IngredientCategory { side, vegetables, other, favorites }

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CategoryCard({
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
        IngredientCategory.side => 'Beilagen auswählen',
        IngredientCategory.vegetables => 'Gemüse auswählen',
        IngredientCategory.other => 'Sonstiges auswählen',
        IngredientCategory.favorites => 'Favoriten auswählen',
      };

  String get subtitle => switch (widget.category) {
        IngredientCategory.side => 'Reis, Nudeln oder Kartoffeln',
        IngredientCategory.vegetables => 'Frisches Gemüse für euer Rezept',
        IngredientCategory.other => 'Alle Lebensmittel außerhalb von Gemüse und Beilagen',
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
    final name = FoodNameNormalizer.normalize(food.name);
    // Keep these items out of the side-dish picker while leaving other beans available.
    if (widget.category == IngredientCategory.side &&
        _containsAny(name, const [
          'weisse bohne', 'kidney bohne', 'grune bohne', 'tortilla', 'toast',
        ])) {
      return false;
    }
    final isPotato = name.contains('kartoffel');
    final isRice = name.contains('reis');
    final isPasta = name.contains('nudel') || name.contains('pasta');

    final isVegetable = category.toLowerCase().contains('gemüse') ||
        category.toLowerCase().contains('vegetable');
    final isSide = _isSideFood(food);

    return switch (widget.category) {
      IngredientCategory.side => isSide,
      IngredientCategory.vegetables => isVegetable && !isPotato,
      IngredientCategory.other => !isVegetable && !isSide,
      IngredientCategory.favorites => preferences[food.id] == 'like',
    };
  }

  bool _containsAny(String value, List<String> terms) =>
      terms.any((term) => FoodNameNormalizer.equivalentOrContains(value, term));

  bool _isSideFood(Food food) {
    final category = food.category.trim();
    final name = FoodNameNormalizer.normalize(food.name);
    if (_containsAny(name, const [
      'weisse bohne', 'kidney bohne', 'grune bohne', 'tortilla', 'toast',
    ])) return false;
    final isPotato = name.contains('kartoffel');
    final isRice = name.contains('reis');
    final isPasta = name.contains('nudel') || name.contains('pasta');
    return isRice || isPasta || isPotato ||
        (category == 'Getreide & Beilagen' &&
            !_containsAny(name, const ['haferflocken', 'semmelbrösel'])) ||
        category == 'Hülsenfrüchte' ||
        _containsAny(name, const [
          'couscous', 'bulgur', 'quinoa', 'gnocchi', 'brot', 'baguette',
          'toast', 'tortilla', 'bohne', 'linsen', 'kichererbse',
        ]);
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
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Material(
                            color: AppDesign.surface,
                            borderRadius: BorderRadius.circular(24),
                            clipBehavior: Clip.antiAlias,
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: foods.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                thickness: 1,
                                indent: 20,
                                endIndent: 20,
                                color: AppDesign.divider,
                              ),
                              itemBuilder: (_, index) {
                                final food = foods[index];
                                final id = food.id;
                                final name = food.name;
                                final checked = selectedFoodIds.contains(id);
                                return _FoodSelectionTile(
                                  name: name,
                                  checked: checked,
                                  onTap: () => _toggle(id),
                                );
                              },
                            ),
                          ),
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
  final VoidCallback onTap;

  const _FoodSelectionTile({
    required this.name,
    required this.checked,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: checked,
      label: name,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
    );
  }
}
