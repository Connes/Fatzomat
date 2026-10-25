import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/together_scaffold.dart';
import '../../core/widgets/together_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/async_error.dart';
import '../../core/app_design.dart';
import '../../core/recipe_collection_events.dart';

import '../../data/models/today_plan.dart';
import '../../data/models/recipe.dart';
import '../../data/models/food.dart';
import '../../data/repositories/food_repository.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../../data/repositories/personal_today_repository.dart';
import '../shared/today_page.dart';

import 'add_recipe_page.dart';
import 'food_preference_recipe_guard.dart';
import 'recipe_detail_page.dart';
import '../../data/services/recipe_image_service.dart';

/// Filters a saved recipe against the cooking summary selection.
///
/// Recipes carry their ingredients in `recipe_ingredients`. The main choice is
/// matched by ingredient name because the existing recipe schema does not store
/// a separate `main_choice` column.
bool recipeModelMatchesSelection(
  Recipe recipe, {
  String? mainChoice,
  Set<String> selectedFoodIds = const <String>{},
  List<Food> availableFoods = const <Food>[],
}) {
  final ingredients = recipe.ingredients;
  final ids = ingredients.map((i) => i.foodId).whereType<String>().toSet();
  if (!selectedFoodIds.every((id) {
    if (ids.contains(id)) return true;
    final food = availableFoods.where((item) => item.id == id).firstOrNull;
    if (food == null) return false;
    final terms = <String>{food.name, ...food.aliases, ...food.searchTerms}
        .map(_normalizeRecipeFoodName)
        .where((term) => term.length >= 3);
    return ingredients.any((ingredient) {
      final name = _normalizeRecipeFoodName(ingredient.name);
      return terms.any((term) => name == term || name.contains(term));
    });
  })) return false;
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


String _normalizeRecipeFoodName(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9äöüß]+'), ' ')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');

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

class _RecipeCardImage extends StatefulWidget {
  final String? imageUrl;
  final String? imagePath;

  const _RecipeCardImage({
    required this.imageUrl,
    required this.imagePath,
  });

  @override
  State<_RecipeCardImage> createState() => _RecipeCardImageState();
}

class _RecipeCardImageState extends State<_RecipeCardImage> {
  String? resolvedUrl;

  @override
  void initState() {
    super.initState();
    resolvedUrl = widget.imageUrl;
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _RecipeCardImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl || oldWidget.imagePath != widget.imagePath) {
      resolvedUrl = widget.imageUrl;
      _resolveImage();
    }
  }

  Future<void> _resolveImage() async {
    if (widget.imageUrl?.trim().isNotEmpty == true) return;
    final path = widget.imagePath?.trim() ?? '';
    if (path.isEmpty) return;
    final url = await RecipeImageService().resolveSignedUrl(path);
    if (mounted && url != null && url.trim().isNotEmpty) {
      setState(() => resolvedUrl = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 88,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: resolvedUrl?.trim().isNotEmpty == true
            ? Image.network(
                resolvedUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => SizedBox.expand(
        child: ColoredBox(
          color: AppDesign.softSurface,
          child: const Center(
            child: Icon(Icons.restaurant_rounded, color: AppDesign.primaryDark),
          ),
        ),
      );
}

class SavedRecipesPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;
  final VoidCallback? onNavigateToToday;
  final String? mainChoice;
  final Set<String> selectedFoodIds;
  final String? decisionRequestId;
  final DateTime? planDate;
  final RecipeRepository? repository;

  const SavedRecipesPage({
    super.key,
    this.onNavigateToTab,
    this.onNavigateToToday,
    this.mainChoice,
    this.selectedFoodIds = const <String>{},
    this.decisionRequestId,
    this.planDate,
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
  List<Food> availableFoods = const <Food>[];
  Map<String, String> foodPreferences = const <String, String>{};
  String query = '';
  String? mainIngredientFilter;
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

  bool get _isSelectedDateToday {
    final date = widget.planDate;
    if (date == null) return true;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String get _selectedDayLabel {
    if (_isSelectedDateToday) return 'heute';
    final date = widget.planDate!;
    return 'am ${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
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

    // Food preferences enrich recipe filtering, but must not make the saved
    // collection unavailable if preference data cannot be loaded offline.
    List<Food> loadedFoods = const <Food>[];
    Map<String, String> loadedPreferences = const <String, String>{};
    try {
      final foodRepository = FoodRepository();
      loadedFoods = await foodRepository.foods();
      loadedPreferences = await foodRepository.preferences();
    } catch (_) {
      // Keep the recipe collection usable when preferences are unavailable.
    }

    // The recipe collection is the primary content of this screen. Connection
    // and Today metadata are auxiliary and must not prevent saved recipes from
    // being displayed when one of those secondary requests fails.
    TodayPlan? today;
    try {
      today = await personalToday.todayPlan(date: widget.planDate);
    } catch (_) {
      // Today is auxiliary metadata. A temporary/unavailable collaboration
      // request must not make the saved recipe collection look broken.
    }

    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      recipes = rows;
      availableFoods = loadedFoods;
      foodPreferences = loadedPreferences;
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


  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatPlanDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  Future<DateTime?> _choosePlanDate() async {
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day);
    final endDate = startDate.add(const Duration(days: 6));
    try {
      final occupiedDays = await personalToday.plannedDayLabels(startDate, endDate);
      if (!mounted) return null;
      return await showDialog<DateTime>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Für welchen Tag möchtest du kochen?'),
          contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: 7,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final date = startDate.add(Duration(days: index));
                final label = occupiedDays[_dateKey(date)];
                final weekdays = const [
                  'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag',
                  'Freitag', 'Samstag', 'Sonntag',
                ];
                final isToday = index == 0;
                return ListTile(
                  key: Key('recipe-plan-date-${_dateKey(date)}'),
                  enabled: label == null,
                  leading: Icon(
                    label == null ? Icons.calendar_today_rounded : Icons.event_busy_rounded,
                    color: label == null ? null : Theme.of(dialogContext).disabledColor,
                  ),
                  title: Text(isToday ? 'Heute · ${_formatPlanDate(date)}' : '${weekdays[date.weekday - 1]} · ${_formatPlanDate(date)}'),
                  subtitle: label == null
                      ? const Text('Frei')
                      : Text('Belegt · $label'),
                  onTap: label == null ? () => Navigator.pop(dialogContext, date) : null,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Abbrechen'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) showAppError(context, error);
      return null;
    }
  }

  Future<void> selectRecipeForToday(Recipe recipe) async {
    if (recipe.id == null) return;
    DateTime? selectedDate = widget.planDate;
    // When opened from the Today flow, TodayPage already owns the chosen date.
    // Only standalone recipe browsing needs to ask the user for a date.
    if (widget.decisionRequestId == null && selectedDate == null) {
      selectedDate = await _choosePlanDate();
      if (selectedDate == null || !mounted) return;
    }
    final planDate = selectedDate ?? DateTime.now();
    try {
      if (widget.decisionRequestId == null) {
        final servings = await showDialog<int>(
          context: context,
          builder: (_) => _ServingsDialog(
            initial: recipe.servings.clamp(1, 12).toInt(),
            confirmLabel: 'Bestätigen',
          ),
        );
        if (servings == null || !mounted) return;
        await personalToday.selectRecipeForToday(
          recipe.id!,
          servings: servings,
          date: planDate,
        );
      } else {
        await collaboration.resolveDecisionRequest(
          requestId: widget.decisionRequestId!,
          decisionMode: 'cook',
          resultType: 'recipe',
          resultId: recipe.id!,
          servings: recipe.servings,
        );
      }
      if (!mounted) return;
      await load();
      if (!mounted) return;

      if (widget.decisionRequestId == null) {
        final navigateToToday = widget.onNavigateToToday;
        if (navigateToToday != null) {
          // Unwind the recipe-search flow to the existing TodayPage. Its
          // selected date is intentionally preserved, including future dates.
          // The shell callback owns both stack unwinding and tab selection.
          // It deliberately does not emit the explicit "reset to today" signal.
          navigateToToday();
          return;
        }
        if (widget.onNavigateToTab != null) {
          widget.onNavigateToTab!(0);
        }
        // Bubble success through a pushed recipe-selection flow when one
        // exists. SavedRecipesPage can also be the root tab itself, where
        // popping would empty the Navigator history and crash the app.
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop(true);
        }
        return;
      }

      AppFeedback.showSnackBar(context, 
        SnackBar(content: Text('„${recipe.name}“ ist für die gemeinsame Entscheidung ausgewählt.')),
      );
    } catch (error) {
      if (mounted) showAppError(context, error);
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
        AppFeedback.showSnackBar(context, 
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
            title: Text(_isSelectedDateToday ? 'Heute ist schon belegt' : 'Dieser Tag ist schon belegt'),
            content: Text('„${todayPlan!.name}“ ist bereits ${_selectedDayLabel} festgelegt. Deine persönliche Einkaufsliste gehört zu diesem Plan.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Schließen')),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TodayPage(initialDate: widget.planDate)));
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

      await personalToday.selectRecipeForToday(recipe.id!, servings: servings, date: widget.planDate);
      if (!mounted) return;
      AppFeedback.showSnackBar(context, 
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
      if (mainIngredientFilter != null &&
          !recipeModelMatchesSelection(
            recipe,
            mainChoice: mainIngredientFilter,
          )) {
        return false;
      }
      if (FoodPreferenceRecipeGuard.findDislikedIngredients(
        recipe: recipe,
        foods: availableFoods,
        preferences: foodPreferences,
      ).isNotEmpty) {
        return false;
      }
      return recipeModelMatchesSelection(
        recipe,
        mainChoice: widget.mainChoice,
        selectedFoodIds: widget.selectedFoodIds,
        availableFoods: availableFoods,
      );
    }).toList(growable: false);
  }


  Future<void> shareRecipe(Recipe recipe) async {
    final ingredients = recipe.ingredients.map((ingredient) {
      final amount = ingredient.isQualitative
          ? ''
          : '${ingredient.quantity} ${ingredient.unit}'.trim();
      return amount.isEmpty ? '• ${ingredient.name}' : '• $amount ${ingredient.name}';
    }).join('\n');
    final steps = recipe.instructions.asMap().entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join('\n');
    final details = [
      recipe.description.trim(),
      'Für ${recipe.servings} Personen',
      if (ingredients.isNotEmpty) 'Zutaten:\n$ingredients',
      if (steps.isNotEmpty) 'Zubereitung:\n$steps',
    ].where((part) => part.trim().isNotEmpty).join('\n\n');

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: recipe.name,
          subject: 'Rezept: ${recipe.name}',
          text: '${recipe.name}\n\n$details',
        ),
      );
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
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
        title: const Text('Rezept aus der gemeinsamen Bibliothek löschen?'),
        content: Text('„${recipe.name}“ ist für alle Nutzer verfügbar. Bei bestehender Connection wird eine Löschanfrage an die verbundene Person gesendet. Das Rezept bleibt bis zur Zustimmung erhalten.'),
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
        AppFeedback.showSnackBar(context, 
          const SnackBar(
            content: Text('Die Löschanfrage wurde an die verbundene Person gesendet. Das Rezept bleibt bis zur ausdrücklichen Zustimmung erhalten.'),
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
    final selectionActive = hasSelectionFilter;

    if (selectionActive) {
      if (visibleRecipes.isEmpty) {
        return TogetherScaffold(
          backgroundType: TogetherBackgroundType.recipes,
          appBar: const TogetherAppBar(title: Text('Meine Rezepte')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: AppDesign.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppDesign.divider),
                ),
                child: Text(
                  'Kein passendes Rezept gefunden.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return TogetherScaffold(
        backgroundType: TogetherBackgroundType.recipes,
        appBar: const TogetherAppBar(title: Text('Meine Rezepte')),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          itemCount: visibleRecipes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final recipe = visibleRecipes[i];
            return SizedBox(
              height: 148,
              child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailPage(
                        recipeId: recipe.id!,
                        planDate: widget.planDate,
                        onTodayPlanChanged: load,
                        onNavigateToToday: widget.onNavigateToToday ??
                            (widget.onNavigateToTab == null
                                ? null
                                : () => widget.onNavigateToTab!(0)),
                        onNavigateToShoppingList: widget.onNavigateToTab == null
                            ? null
                            : () => widget.onNavigateToTab!(2),
                      ),
                    ),
                  );
                  if (mounted) load();
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RecipeCardImage(
                        imageUrl: recipe.imageUrl,
                        imagePath: recipe.imagePath,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(recipe.name, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                key: Key('cook-search-select-recipe-${recipe.id}'),
                                onPressed: () => selectRecipeForToday(recipe),
                                icon: const Icon(Icons.event_available_rounded, size: 18),
                                label: Text(
                                  widget.planDate == null || _isSelectedDateToday
                                      ? 'Für heute auswählen'
                                      : 'Für diesen Tag auswählen',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            );
          },
        ),
      );
    }

    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.recipes,
      appBar: TogetherAppBar(
        leading: PopupMenuButton<String>(
          tooltip: 'Rezepte nach Hauptzutat filtern',
          initialValue: mainIngredientFilter ?? 'Alle',
          onSelected: (value) => setState(
            () => mainIngredientFilter = value == 'Alle' ? null : value,
          ),
          icon: Icon(
            Icons.tune_rounded,
            size: 22,
            color: mainIngredientFilter == null
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.primary,
          ),
          color: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: .12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .65),
            ),
          ),
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
          menuPadding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (_) {
            const options = <(String, IconData)>[
              ('Alle', Icons.grid_view_rounded),
              ('Schwein', Icons.restaurant_rounded),
              ('Rind', Icons.restaurant_rounded),
              ('Huhn', Icons.restaurant_rounded),
              ('Vegetarisch', Icons.eco_rounded),
              ('Fisch', Icons.set_meal_rounded),
            ];
            final selected = mainIngredientFilter ?? 'Alle';
            return options.map((option) {
              final value = option.$1;
              final isSelected = selected == value;
              return PopupMenuItem<String>(
                value: value,
                height: 48,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppDesign.secondarySurface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        option.$2,
                        size: 20,
                        color: isSelected
                            ? AppDesign.primaryDark
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          value == 'Alle' ? 'Alle Rezepte' : value,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppDesign.primaryDark
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppDesign.primaryDark,
                        ),
                    ],
                  ),
                ),
              );
            }).toList();
          },
        ),
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
                        return SizedBox(
                          height: 148,
                          child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecipeDetailPage(
                                    recipeId: recipe.id!,
                                    planDate: widget.planDate,
                                    onTodayPlanChanged: load,
                                    onNavigateToToday: widget.onNavigateToToday ??
                                        (widget.onNavigateToTab == null
                                            ? null
                                            : () => widget.onNavigateToTab!(0)),
                                    onNavigateToShoppingList: widget.onNavigateToTab == null
                                        ? null
                                        : () => widget.onNavigateToTab!(2),
                                  ),
                                ),
                              );
                              if (mounted) load();
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _RecipeCardImage(
                                    imageUrl: recipe.imageUrl,
                                    imagePath: recipe.imagePath,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 48,
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: Text(
                                              (recipe.name.length > 40 ? '${recipe.name.substring(0, 40).trimRight()}…' : recipe.name),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            key: Key('saved-recipe-select-today-${recipe.id}'),
                                            onPressed: () => selectRecipeForToday(recipe),
                                            icon: const Icon(Icons.event_available_rounded, size: 18),
                                            label: const Text('Auswählen'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: 'Rezeptoptionen',
                                    onSelected: (value) {
                                      if (value == 'edit') editRecipe(recipe);
                                      if (value == 'delete') deleteRecipe(recipe);
                                      if (value == 'share') shareRecipe(recipe);
                                    },
                                    color: AppDesign.surfaceSoft,
                                    surfaceTintColor: Colors.transparent,
                                    elevation: 10,
                                    shadowColor: Colors.black.withValues(alpha: .14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppDesign.radiusLg),
                                      side: const BorderSide(color: AppDesign.divider),
                                    ),
                                    constraints: const BoxConstraints(minWidth: 232, maxWidth: 280),
                                    menuPadding: const EdgeInsets.symmetric(vertical: 6),
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        height: 48,
                                        child: ListTile(
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                          leading: Icon(Icons.edit_outlined, color: AppDesign.secondaryText),
                                          title: Text('Rezept bearbeiten'),
                                        ),
                                      ),
                                      const PopupMenuDivider(height: 1),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        height: 48,
                                        child: ListTile(
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                          leading: Icon(Icons.delete_outline_rounded, color: AppDesign.error),
                                          title: Text('Rezept löschen', style: TextStyle(color: AppDesign.error)),
                                        ),
                                      ),
                                      const PopupMenuDivider(height: 1),
                                      const PopupMenuItem(
                                        value: 'share',
                                        height: 48,
                                        child: ListTile(
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                          leading: Icon(Icons.share_outlined, color: AppDesign.secondaryText),
                                          title: Text('Rezept teilen'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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

class _ServingsDialog extends StatefulWidget {
  final int initial;
  final String confirmLabel;
  const _ServingsDialog({
    required this.initial,
    this.confirmLabel = 'Zur Einkaufsliste',
  });

  @override
  State<_ServingsDialog> createState() => _ServingsDialogState();
}

class _ServingsDialogState extends State<_ServingsDialog> {
  late int servings = widget.initial;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Für wie viele Personen?'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.start,
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
          FilledButton(
            onPressed: () => Navigator.pop(context, servings),
            child: Text(widget.confirmLabel),
          ),
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
