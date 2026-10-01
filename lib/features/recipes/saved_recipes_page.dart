import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/widgets/together_scaffold.dart';
import '../../core/widgets/together_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/async_error.dart';
import '../../core/app_design.dart';
import '../../core/error_text.dart';
import '../../core/recipe_collection_events.dart';

import '../../data/models/today_plan.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../../data/repositories/personal_today_repository.dart';
import '../shared/today_page.dart';

import 'add_recipe_page.dart';
import 'recipe_detail_page.dart';

/// Filters a saved recipe against the cooking summary selection.
///
/// Recipes carry their ingredients in `recipe_ingredients`. The main choice is
/// matched by ingredient name because the existing recipe schema does not store
/// a separate `main_choice` column.
bool recipeModelMatchesSelection(
  Recipe recipe, {
  String? mainChoice,
  Set<String> selectedFoodIds = const <String>{},
}) {
  final ids = recipe.ingredients.map((i) => i.foodId).whereType<String>().toSet();
  if (!selectedFoodIds.every(ids.contains)) return false;
  if (mainChoice == null || mainChoice.isEmpty) return true;
  final names = recipe.ingredients.map((i) => i.name.toLowerCase()).toList();
  if (mainChoice == 'Vegetarisch') {
    const forbidden = ['rind', 'schwein', 'huhn', 'hähnchen', 'pute', 'truthahn', 'lamm', 'wild', 'fisch', 'lachs', 'thunfisch', 'garnelen', 'shrimp', 'meeresfrucht'];
    return !names.any((name) => forbidden.any(name.contains));
  }
  final needles = switch (mainChoice) {
    'Rind' => const ['rind', 'rinder', 'beef'],
    'Schwein' => const ['schwein', 'schweine', 'pork'],
    'Huhn' => const ['huhn', 'hähnchen', 'haehnchen', 'chicken', 'pute', 'truthahn'],
    'Fisch' => const ['fisch', 'lachs', 'thunfisch', 'forelle', 'kabeljau', 'garnelen', 'garnele', 'shrimp'],
    _ => <String>[],
  };
  return needles.isEmpty || names.any((name) => needles.any(name.contains));
}


/// Legacy map-based compatibility helper used by regression tests. New code
/// should use [recipeModelMatchesSelection] with the typed [Recipe] model.
bool recipeMatchesSelection(
  Map<String, dynamic> recipe, {
  String? mainChoice,
  Set<String> selectedFoodIds = const <String>{},
}) {
  final ingredients = (recipe['recipe_ingredients'] as List?)
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false) ??
      const <Map<String, dynamic>>[];
  final ids = ingredients.map((i) => i['food_id']?.toString()).whereType<String>().toSet();
  if (!selectedFoodIds.every(ids.contains)) return false;
  if (mainChoice == null || mainChoice.isEmpty) return true;
  final names = ingredients.map((i) => (i['name']?.toString() ?? '').toLowerCase()).toList();
  if (mainChoice == 'Vegetarisch') {
    const forbidden = ['rind', 'schwein', 'huhn', 'hähnchen', 'pute', 'truthahn', 'lamm', 'wild', 'fisch', 'lachs', 'thunfisch', 'garnelen', 'shrimp', 'meeresfrucht'];
    return !names.any((name) => forbidden.any(name.contains));
  }
  final needles = switch (mainChoice) {
    'Rind' => const ['rind', 'rinder', 'beef'],
    'Schwein' => const ['schwein', 'schweine', 'pork'],
    'Huhn' => const ['huhn', 'hähnchen', 'haehnchen', 'chicken', 'pute', 'truthahn'],
    'Fisch' => const ['fisch', 'lachs', 'thunfisch', 'forelle', 'kabeljau', 'garnelen', 'garnele', 'shrimp'],
    _ => <String>[],
  };
  return needles.isEmpty || names.any((name) => needles.any(name.contains));
}

class SavedRecipesPage extends StatefulWidget {
  final String? mainChoice;
  final Set<String> selectedFoodIds;
  final String? decisionRequestId;
  final RecipeRepository? repository;

  const SavedRecipesPage({
    super.key,
    this.mainChoice,
    this.selectedFoodIds = const <String>{},
    this.decisionRequestId,
    this.repository,
  });

  @override
  State<SavedRecipesPage> createState() => _SavedRecipesPageState();
}

class _SavedRecipesPageState extends State<SavedRecipesPage> {
  late final RecipeRepository repo = widget.repository ?? RecipeRepository();
  final collaboration = CollaborationRepository();
  final personalToday = PersonalTodayRepository();
  final searchController = TextEditingController();
  bool loading = true;
  List<Recipe> recipes = [];
  String query = '';
  TodayPlan? todayPlan;
  RealtimeChannel? realtimeChannel;

  @override
  void initState() {
    super.initState();
    if (!_supabaseAvailable()) {
      loading = false;
      return;
    }
    load();
    RecipeCollectionEvents.revision.addListener(_onRecipeCollectionChanged);
    _subscribeRealtime();
  }

  bool _supabaseAvailable() {
    try {
      Supabase.instance.client;
      return true;
    } on AssertionError {
      // Widget tests and offline previews may intentionally run without Supabase.
      return false;
    }
  }

  @override
  void dispose() {
    RecipeCollectionEvents.revision.removeListener(_onRecipeCollectionChanged);
    _reloadTimer?.cancel();
    if (realtimeChannel != null) {
      try {
        Supabase.instance.client.removeChannel(realtimeChannel!);
      } on AssertionError {
        // Supabase may be unavailable in widget tests/offline previews.
      }
    }
    searchController.dispose();
    super.dispose();
  }

  void _subscribeRealtime() {
    try {
      final client = Supabase.instance.client;
    realtimeChannel = client.channel('saved-recipes-${client.auth.currentUser?.id ?? 'current'}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'recipes',
        callback: (_) => _reloadSoon(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'personal_today_plans',
        callback: (_) => _reloadSoon(),
      )
      ..subscribe();
    } on AssertionError {
      // Widget tests and offline previews can mount before Supabase exists.
    }
  }

  Timer? _reloadTimer;
  int _loadGeneration = 0;

  void _onRecipeCollectionChanged() {
    if (mounted) _reloadSoon();
  }

  void _reloadSoon() {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) load();
    });
  }


  Future<void> load() async {
    final generation = ++_loadGeneration;
    Object? recipeError;
    List<Recipe> rows = const <Recipe>[];

    try {
      rows = await repo.savedRecipeModels();
    } catch (error) {
      recipeError = error;
    }

    // The recipe collection is the primary content of this screen. Connection
    // and Today metadata are auxiliary and must not prevent saved recipes from
    // being displayed when one of those secondary requests fails.
    TodayPlan? today;
    try {
      today = await personalToday.todayPlan();
    } catch (_) {
      // Today is auxiliary metadata. A temporary/unavailable collaboration
      // request must not make the saved recipe collection look broken.
    }

    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      recipes = rows;
      todayPlan = today;
      loading = false;
    });

    // Only a failure to load the recipes themselves is a screen-level error.
    // Today and connection state are optional metadata and intentionally stay
    // silent when unavailable. The recipe collection must remain usable.
    if (recipeError != null && generation == _loadGeneration) {
      final e = recipeError;
      showAppError(context, e);
      return;
    }
  }

  Future<void> addFavorite() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddRecipePage()),
    );
    if (added == true) await load();
  }


  Future<void> selectRecipeForToday(Recipe recipe) async {
    if (recipe.id == null) return;
    try {
      if (widget.decisionRequestId == null) {
        await personalToday.selectRecipeForToday(
          recipe.id!,
          servings: recipe.servings.clamp(1, 12).toInt(),
        );
      }
      if (widget.decisionRequestId != null) {
        try {
          await collaboration.resolveDecisionRequest(
            requestId: widget.decisionRequestId!,
            decisionMode: 'cook',
            resultType: 'recipe',
            resultId: recipe.id!,
            servings: recipe.servings,
          );
        } catch (error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rezept für heute gesetzt. Die gemeinsame Anfrage konnte noch nicht aktualisiert werden: ${friendlyError(error)}')),
          );
        }
      }
      if (!mounted) return;
      // SavedRecipesPage is a persistent tab inside AppShell's IndexedStack,
      // not a route pushed onto the Navigator stack. Popping here can therefore
      // empty the root Navigator history and trigger Flutter's
      // `_history.isNotEmpty` assertion. Refresh the tab state instead.
      await load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('„${recipe.name}“ ist für heute ausgewählt.')),
      );
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> addRecipeToShoppingList(Recipe recipe) async {
    if (recipe.id == null) return;

    try {
      final connection = await collaboration.connectionInfo();
      final isConnected = connection?.isConnected == true;

      if (isConnected) {
        final existingShared = await collaboration.currentSharedRecipePlan();
        if (existingShared != null) {
          if (!mounted) return;
          final recipeMap = existingShared['recipes'] is Map
              ? Map<String, dynamic>.from(existingShared['recipes'] as Map)
              : const <String, dynamic>{};
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShoppingPage(
                planId: existingShared['id'].toString(),
                recipeName: recipeMap['name']?.toString() ?? 'Gemeinsame Einkaufsliste',
                servings: (existingShared['servings'] as num?)?.toInt() ?? 2,
                shared: true,
              ),
            ),
          );
          return;
        }

        final servings = await showDialog<int>(
          context: context,
          builder: (_) => _ServingsDialog(
            initial: recipe.servings < 1 ? 1 : (recipe.servings > 12 ? 12 : recipe.servings),
          ),
        );
        if (servings == null || !mounted) return;

        final planId = await collaboration.shareRecipeForToday(recipe.id!, servings: servings);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gemeinsames Rezept hinzugefügt. Eure Einkaufsliste ist jetzt vorbereitet.')),
        );
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShoppingPage(
              planId: planId,
              recipeName: recipe.name,
              servings: servings,
              shared: true,
            ),
          ),
        );
        await load();
        return;
      }

      if (todayPlan != null) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Heute ist schon belegt'),
            content: Text('„${todayPlan!.name}“ ist bereits für heute festgelegt. Deine persönliche Einkaufsliste gehört zu diesem Plan.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Schließen')),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TodayPage()));
                },
                child: const Text('Heute öffnen'),
              ),
            ],
          ),
        );
        return;
      }

      final baseServings = recipe.servings;
      final servings = await showDialog<int>(
        context: context,
        builder: (_) => _ServingsDialog(initial: baseServings < 1 ? 1 : (baseServings > 12 ? 12 : baseServings)),
      );
      if (servings == null || !mounted) return;

      await personalToday.selectRecipeForToday(recipe.id!, servings: servings);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezept hinzugefügt. Deine persönliche Einkaufsliste ist jetzt vorbereitet.')),
      );
      await load();
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }


  bool get hasSelectionFilter => widget.mainChoice != null || widget.selectedFoodIds.isNotEmpty;

  List<Recipe> get visibleRecipes {
    final normalizedQuery = query.trim().toLowerCase();
    return recipes.where((recipe) {
      if (normalizedQuery.isNotEmpty &&
          !recipe.name.toLowerCase().contains(normalizedQuery) &&
          !recipe.description.toLowerCase().contains(normalizedQuery)) {
        return false;
      }
      return recipeModelMatchesSelection(
        recipe,
        mainChoice: widget.mainChoice,
        selectedFoodIds: widget.selectedFoodIds,
      );
    }).toList(growable: false);
  }


  Future<void> editRecipe(Recipe recipe) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ManualRecipePage(initialRecipe: recipe)),
    );
    if (changed == true && mounted) await load();
  }

  Future<void> deleteRecipe(Recipe recipe) async {
    if (recipe.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rezept aus deiner Sammlung entfernen?'),
        content: Text('„${recipe.name}“ wird aus deiner Rezeptsammlung entfernt. Wenn es heute eingeplant ist oder noch von der verbundenen Person gespeichert wird, bleibt das Rezept erhalten.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final removed = await repo.removeRecipeFromCollection(recipe.id!);
      if (!removed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Das Rezept bleibt erhalten, weil es noch von der verbundenen Person gespeichert oder für heute eingeplant ist.'),
          ),
        );
      }
      await load();
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TogetherScaffold(backgroundType: TogetherBackgroundType.recipes, 
      appBar: TogetherAppBar(
        title: const Text('Meine Rezepte'),
        actions: [
          IconButton(
            tooltip: 'Rezept hinzufügen',
            onPressed: loading ? null : addFavorite,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (todayPlan != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                    child: Material(
                      color: const Color(0xFFDDF3E7),
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TodayPage()),
                        ).then((_) => load()),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite_rounded, color: AppDesign.primaryDark),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Für dich heute', style: Theme.of(context).textTheme.bodyMedium),
                                    const SizedBox(height: 2),
                                    Text(
                                      todayPlan!.name,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (hasSelectionFilter)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.selectedFoodIds.isEmpty
                            ? 'Passend zu deiner Auswahl'
                            : 'Passend zu deiner Auswahl · ${widget.selectedFoodIds.length} zusätzliche Zutaten',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                if (recipes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) => setState(() => query = value),
                      decoration: InputDecoration(
                        hintText: 'Rezepte suchen',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  setState(() => query = '');
                                },
                                icon: const Icon(Icons.clear_rounded),
                              ),
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: load,
                    child: ListView.separated(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                      itemCount: visibleRecipes.isEmpty ? 1 : visibleRecipes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        if (visibleRecipes.isEmpty) {
                          return recipes.isEmpty
                              ? const SavedRecipesEmptyState()
                              : Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 32),
                                    child: Text('Kein passendes Rezept gefunden.', style: Theme.of(context).textTheme.bodyMedium),
                                  ),
                                );
                        }

                        final recipe = visibleRecipes[i];
                        final total = recipe.prepTimeMinutes + recipe.cookTimeMinutes;
                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => RecipeDetailPage(recipeId: recipe.id!)),
                              );
                              if (mounted) load();
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: SizedBox(
                                      width: 58,
                                      height: 58,
                                      child: recipe.imageUrl?.trim().isNotEmpty == true
                                          ? Image.network(
                                              recipe.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: AppDesign.softSurface,
                                                alignment: Alignment.center,
                                                child: const Icon(Icons.restaurant_rounded, color: AppDesign.primaryDark),
                                              ),
                                            )
                                          : Container(
                                              color: AppDesign.softSurface,
                                              alignment: Alignment.center,
                                              child: const Icon(Icons.restaurant_rounded, color: AppDesign.primaryDark),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(recipe.name, style: Theme.of(context).textTheme.titleMedium),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${recipe.servings} Personen · $total Min. · ${_difficulty(recipe.difficulty)}',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            key: Key('saved-recipe-select-today-${recipe.id}'),
                                            onPressed: () => selectRecipeForToday(recipe),
                                            icon: const Icon(Icons.today_rounded, size: 18),
                                            label: const Text('Für heute auswählen'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'today') selectRecipeForToday(recipe);
                                      if (value == 'delete') deleteRecipe(recipe);
                                      if (value == 'shopping') addRecipeToShoppingList(recipe);
                                      if (value == 'edit') editRecipe(recipe);
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'today', child: Text('Für heute auswählen')),
                                      const PopupMenuItem(value: 'shopping', child: Text('Zur Einkaufsliste hinzufügen')),
                                      const PopupMenuItem(value: 'edit', child: Text('Rezept bearbeiten')),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: const Text('Löschen'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              ],
            ),
    );
  }

  String _difficulty(String value) {
    switch (value) {
      case 'easy':
        return 'Einfach';
      case 'medium':
        return 'Mittel';
      case 'hard':
        return 'Aufwendig';
      default:
        return value;
    }
  }
}

class _ServingsDialog extends StatefulWidget {
  final int initial;
  const _ServingsDialog({required this.initial});

  @override
  State<_ServingsDialog> createState() => _ServingsDialogState();
}

class _ServingsDialogState extends State<_ServingsDialog> {
  late int servings = widget.initial;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Für wie viele Personen?'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Weniger',
              onPressed: servings > 1 ? () => setState(() => servings--) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            SizedBox(
              width: 100,
              child: Text('$servings Personen', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton(
              tooltip: 'Mehr',
              onPressed: servings < 12 ? () => setState(() => servings++) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, servings), child: const Text('Zur Einkaufsliste')),
        ],
      );
}


class SavedRecipesEmptyState extends StatelessWidget {
  const SavedRecipesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SizedBox(
          key: const ValueKey<String>('my_recipes_empty_state'),
          width: double.infinity,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            decoration: BoxDecoration(
              color: AppDesign.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppDesign.divider),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Noch keine Rezepte in deiner Sammlung',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Finde ein Rezept oder füge ein Lieblingsrezept hinzu.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
