import 'package:flutter/material.dart';

import '../../core/widgets/together_scaffold.dart';
import '../../core/widgets/together_background.dart';

import '../../core/async_error.dart';
import '../../core/app_design.dart';
import '../../core/constants.dart';
import '../../data/repositories/food_repository.dart';
import '../../data/models/food.dart';
import '../../data/repositories/profile_repository.dart';
import '../recipes/add_favorite_recipe_dialog.dart';
import 'add_food_dialog.dart';

class FoodOnboardingPage extends StatefulWidget {
  final VoidCallback onCompleted;

  const FoodOnboardingPage({super.key, required this.onCompleted});

  @override
  State<FoodOnboardingPage> createState() => _FoodOnboardingPageState();
}

class _FoodOnboardingPageState extends State<FoodOnboardingPage> {
  final repository = FoodRepository();
  final searchController = TextEditingController();
  final prefs = <String, String>{};
  List<Food> foods = [];
  bool loading = true;
  bool saving = false;
  String category = 'Alle';
  bool showSetup = false;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_refresh);
    load();
  }

  @override
  void dispose() {
    searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> load() async {
    try {
      final rows = await repository.foods();
      final existing = await repository.preferences();
      if (!mounted) return;
      setState(() {
        foods = rows;
        prefs.addAll(existing);
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppError(context, error);
    }
  }

  List<String> get categories {
    final values = foods.map((f) => f.category).toSet();
    final ordered = foodCategories.where(values.contains).toList();
    final extras = values.where((value) => !foodCategories.contains(value)).toList()..sort();
    return ['Alle', ...ordered, ...extras];
  }

  List<Food> get visibleFoods {
    final query = searchController.text.trim().toLowerCase();
    return foods.where((food) {
      final foodCategory = food.category;
      if (category != 'Alle' && foodCategory != category) return false;
      if (query.isEmpty) return true;
      final name = food.name.toLowerCase();
      final terms = [...food.searchTerms, ...food.aliases];
      return name.contains(query) || terms.any((term) => term.toLowerCase().contains(query));
    }).toList();
  }

  void choose(String id, String value) {
    setState(() {
      if (prefs[id] == value) {
        prefs.remove(id);
      } else {
        prefs[id] = value;
      }
    });
  }

  Future<void> addFood() async {
    final result = await showDialog<Food>(
      context: context,
      builder: (_) => AddFoodDialog(
        initialCategory: category == 'Alle' ? null : category,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      foods.add(result);
      prefs[result.id] = 'like';
    });
  }

  Future<void> addFavoriteRecipe() async {
    await showDialog<bool>(
      context: context,
      builder: (_) => const AddFavoriteRecipeDialog(),
    );
  }

  Future<void> finish() async {
    setState(() => saving = true);
    try {
      await ProfileRepository().completeOnboarding(prefs);
      if (mounted) widget.onCompleted();
    } catch (error) {
      if (mounted) showAppError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!showSetup) {
      return TogetherScaffold(
        backgroundType: TogetherBackgroundType.settings,
        body: SafeArea(
          child: _FoodOnboardingIntro(
            onStart: () => setState(() => showSetup = true),
          ),
        ),
      );
    }

    if (loading) {
      return const TogetherScaffold(
        backgroundType: TogetherBackgroundType.settings,
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final shown = visibleFoods;
    final liked = prefs.values.where((value) => value == 'like').length;
    final disliked = prefs.values.where((value) => value == 'dislike').length;

    return TogetherScaffold(
      backgroundType: TogetherBackgroundType.settings,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppDesign.softSurface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppDesign.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            'assets/branding/app_icon.png',
                            key: const ValueKey<String>('food_onboarding_setup_app_logo'),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Kurz einrichten',
                          key: const ValueKey<String>('food_onboarding_setup_title'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Markiere, was du magst oder lieber auslässt.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final value = categories[index];
                        return ChoiceChip(
                          label: Text(value),
                          selected: category == value,
                          onSelected: (_) => setState(() => category = value),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _CountPill(icon: Icons.favorite_rounded, text: '$liked', color: AppDesign.primaryDark),
                      const SizedBox(width: 8),
                      _CountPill(icon: Icons.block_rounded, text: '$disliked', color: AppDesign.secondaryText),
                      const Spacer(),
                      IconButton(
                        key: const ValueKey<String>('food_onboarding_add_food_button'),
                        tooltip: 'Eigenes Lebensmittel hinzufügen',
                        onPressed: saving ? null : addFood,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        'Nichts gefunden. Du kannst Lebensmittel später jederzeit hinzufügen.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    ...shown.map((food) {
                      final id = food.id;
                      final value = prefs[id];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: value == 'like'
                                        ? const Color(0xFFDDF3E7)
                                        : value == 'dislike'
                                            ? AppDesign.softSurface
                                            : const Color(0xFFFFF8F2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    value == 'like'
                                        ? Icons.favorite_rounded
                                        : value == 'dislike'
                                            ? Icons.block_rounded
                                            : Icons.restaurant_rounded,
                                    color: value == 'like' ? AppDesign.primaryDark : AppDesign.secondaryText,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(food.name, style: Theme.of(context).textTheme.titleMedium),
                                      const SizedBox(height: 2),
                                      Text(food.category, style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Mag ich',
                                  onPressed: saving ? null : () => choose(id, 'like'),
                                  icon: Icon(Icons.favorite_rounded, color: value == 'like' ? AppDesign.primary : AppDesign.divider),
                                ),
                                IconButton(
                                  tooltip: 'Mag ich nicht',
                                  onPressed: saving ? null : () => choose(id, 'dislike'),
                                  icon: Icon(Icons.block_rounded, color: value == 'dislike' ? AppDesign.secondaryText : AppDesign.divider),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: saving ? null : finish,
                    icon: saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Auswahl speichern'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodOnboardingIntro extends StatelessWidget {
  final VoidCallback onStart;

  const _FoodOnboardingIntro({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSurface(
                  key: const ValueKey<String>('food_onboarding_welcome_box'),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                'assets/branding/app_icon.png',
                                key: const ValueKey<String>('food_onboarding_brand_logo'),
                                width: 46,
                                height: 46,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'SCHMACKOFATZ',
                              key: const ValueKey<String>('food_onboarding_brand_title'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Divider(
                          key: ValueKey<String>('food_onboarding_brand_divider'),
                        ),
                      ),
                      Text(
                        'Willkommen!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Richte zuerst deine Lebensmittel und Vorlieben ein. '
                        'Schmackofatz nutzt deine Auswahl für passende Essensideen, hilft dir beim Tagesplan '
                        'und erstellt daraus deine Einkaufsliste. Mit Connections kannst du Rezepte und Planung gemeinsam nutzen.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey<String>('food_onboarding_start_button'),
                    onPressed: onStart,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Lebensmittel einrichten'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _CountPill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppDesign.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
