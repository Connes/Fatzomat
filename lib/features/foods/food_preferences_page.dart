import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/widgets/together_scaffold.dart';
import '../../core/widgets/together_background.dart';
import '../../core/app_design.dart';
import 'add_food_dialog.dart';
import '../../core/async_error.dart';
import '../../data/repositories/food_repository.dart';
import '../../data/models/food.dart';

import 'food_filter.dart';

class FoodPreferencesPage extends StatefulWidget {
  const FoodPreferencesPage({super.key});

  @override
  State<FoodPreferencesPage> createState() => _FoodPreferencesPageState();
}

class _FoodPreferencesPageState extends State<FoodPreferencesPage> {
  final searchController = TextEditingController();
  final repository = FoodRepository();
  List<Food> foods = [];
  Map<String, String> preferences = {};
  bool loading = true;
  bool saving = false;
  String preferenceFilter = 'all';
  String categoryFilter = 'Alle';

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    load();
  }

  @override
  void dispose() {
    searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  Future<void> load() async {
    try {
      final foodRows = await repository.foods();
      final loadedPreferences = await repository.preferences();
      if (!mounted) return;
      setState(() {
        foods = foodRows;
        preferences = loadedPreferences;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppError(context, error);
    }
  }

  Future<void> addFood() async {
    final result = await showDialog<Food>(
      context: context,
      builder: (_) => AddFoodDialog(
        initialCategory: categoryFilter == 'Alle' ? null : categoryFilter,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      foods.add(result);
      preferences[result.id] = 'like';
    });
  }

  Future<void> setPreference(String foodId, String preference) async {
    final current = preferences[foodId];
    setState(() => saving = true);
    try {
      if (current == preference) {
        await repository.clearPreference(foodId);
        if (mounted) setState(() => preferences.remove(foodId));
      } else {
        await repository.setPreference(foodId, preference);
        if (mounted) setState(() => preferences[foodId] = preference);
      }
    } catch (error) {
      if (mounted) showAppError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  List<String> get categories {
    final values = foods.map((food) => food.category).toSet().toList()..sort();
    return ['Alle', ...values];
  }

  List<Food> get filteredFoods {
    return filterFoods(
      foods: foods,
      preferences: preferences,
      query: searchController.text,
      preferenceFilter: preferenceFilter,
      categoryFilter: categoryFilter,
    );
  }

  int get likedCount => preferences.values.where((value) => value == 'like').length;
  int get dislikedCount => preferences.values.where((value) => value == 'dislike').length;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const TogetherScaffold(backgroundType: TogetherBackgroundType.settings, appBar: TogetherAppBar(title: Text('Meine Lebensmittel')), body: Center(child: CircularProgressIndicator()));
    }

    return TogetherScaffold(backgroundType: TogetherBackgroundType.settings, 
      appBar: TogetherAppBar(
        title: const Text('Meine Lebensmittel'),
        actions: [
          IconButton(
            tooltip: 'Lebensmittel hinzufügen',
            onPressed: saving ? null : addFood,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Neu laden',
            onPressed: saving ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Lebensmittel suchen',
                hintText: 'z. B. Tomate, Reis, Käse',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Suche löschen',
                        onPressed: searchController.clear,
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.favorite, size: 16),
                  label: Text('$likedCount mag ich'),
                ),
                const SizedBox(width: 8),
                Chip(
                  avatar: const Icon(Icons.block, size: 16),
                  label: Text('$dislikedCount nicht'),
                ),
                const Spacer(),
                if (saving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('Alle'),
                  selected: preferenceFilter == 'all',
                  onSelected: (_) => setState(() => preferenceFilter = 'all'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('❤️ Mag ich'),
                  selected: preferenceFilter == 'like',
                  onSelected: (_) => setState(() => preferenceFilter = 'like'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('🚫 Mag ich nicht'),
                  selected: preferenceFilter == 'dislike',
                  onSelected: (_) => setState(() => preferenceFilter = 'dislike'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final category = categories[index];
                return FilterChip(
                  label: Text(category),
                  selected: categoryFilter == category,
                  onSelected: (_) => setState(() => categoryFilter = category),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
              child: filteredFoods.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: AppSurface(
                          key: const ValueKey<String>('food_preferences_empty_state_box'),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          color: AppDesign.surface.withValues(alpha: 0.97),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, size: 38, color: AppDesign.primaryDark),
                              const SizedBox(height: 12),
                              Text(
                                'Keine Lebensmittel gefunden.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppDesign.text,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ändere Suche oder Filter.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppDesign.secondaryText,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final desiredHeight = (filteredFoods.length * 72.0 + 20.0)
                            .clamp(140.0, 420.0)
                            .toDouble();
                        final boxHeight = math.min(desiredHeight, constraints.maxHeight);

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: AppSurface(
                              key: const ValueKey<String>('food_preferences_list_box'),
                              padding: const EdgeInsets.all(8),
                              color: AppDesign.surface.withValues(alpha: 0.96),
                              child: SizedBox(
                                width: double.infinity,
                                height: boxHeight,
                                child: Scrollbar(
                                  thumbVisibility: true,
                                  child: ListView.builder(
                                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                    itemCount: filteredFoods.length,
                                    itemBuilder: (context, index) {
                                      final food = filteredFoods[index];
                                      final id = food.id;
                                      final name = food.name;
                                      final category = food.category;
                                      final preference = preferences[id];

                                      return ListTile(
                                        dense: false,
                                        title: Text(name),
                                        subtitle: Text(category),
                                        leading: CircleAvatar(
                                          child: Icon(
                                            preference == 'like'
                                                ? Icons.favorite
                                                : preference == 'dislike'
                                                    ? Icons.block
                                                    : Icons.restaurant,
                                          ),
                                        ),
                                        trailing: Wrap(
                                          spacing: 0,
                                          children: [
                                            IconButton(
                                              tooltip: preference == 'like' ? 'Mag ich entfernen' : 'Mag ich',
                                              onPressed: saving ? null : () => setPreference(id, 'like'),
                                              icon: Icon(
                                                Icons.favorite,
                                                color: preference == 'like' ? Colors.red : Colors.grey,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: preference == 'dislike' ? 'Nicht mögen entfernen' : 'Mag ich nicht',
                                              onPressed: saving ? null : () => setPreference(id, 'dislike'),
                                              icon: Icon(
                                                Icons.block,
                                                color: preference == 'dislike' ? Colors.black : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
