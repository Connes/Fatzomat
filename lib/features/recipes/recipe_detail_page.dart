import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/together_scaffold.dart';
import '../../core/widgets/together_background.dart';
import '../../core/app_design.dart';
import '../../core/async_error.dart';
import '../../core/error_text.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/personal_today_repository.dart';
import '../../data/models/recipe.dart';
import '../../data/services/together_recipe_file_service.dart';
import '../../data/services/recipe_image_service.dart';
import '../shared/today_page.dart';
import 'add_recipe_page.dart';

class RecipeDetailPage extends StatefulWidget {
  final String recipeId;
  final Future<void> Function()? onTodayPlanChanged;
  final VoidCallback? onNavigateToToday;
  final bool canMarkCooked;
  const RecipeDetailPage({
    super.key,
    required this.recipeId,
    this.onTodayPlanChanged,
    this.onNavigateToToday,
    this.canMarkCooked = false,
  });
  @override State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

List<(String?, List<RecipeIngredient>)> _groupIngredients(List<RecipeIngredient> ingredients) {
  final groups = <String?, List<RecipeIngredient>>{};
  for (final ingredient in ingredients) {
    final section = ingredient.section?.trim();
    groups.putIfAbsent(section == null || section.isEmpty ? null : section, () => <RecipeIngredient>[]).add(ingredient);
  }
  return groups.entries.map((entry) => (entry.key, List<RecipeIngredient>.unmodifiable(entry.value))).toList(growable: false);
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final repo = RecipeRepository();
  final personalToday = PersonalTodayRepository();
  Recipe? recipe;
  Object? loadError;
  bool loading = true, working = false, personalTodaySelected = false, cookedMarked = false;
  int servings = 2;
  final Set<int> completedSteps = <int>{};
  bool ingredientsExpanded = false;
  bool preparationExpanded = false;

  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final r = await repo.getRecipeModel(widget.recipeId);
      bool selectedForToday = false;
      try {
        final today = await personalToday.todayPlan();
        selectedForToday = today?.isRecipe == true &&
            today?.recipeId == widget.recipeId &&
            today?.status != 'cooked';
      } catch (_) {
        // Personal Today state is optional metadata for recipe rendering.
      }
      if (!mounted) return;
      setState(() { recipe = r; loadError = null; servings = r.servings.clamp(1, 12).toInt(); personalTodaySelected = selectedForToday; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; loadError = e; });
    }
  }

  double scaled(num base) => base.toDouble() * servings / recipe!.servings.clamp(1, 12).toDouble();
  String formatQuantity(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(value < 10 ? 1 : 0);
  String difficulty(String value) => switch (value) { 'easy' => 'Einfach', 'medium' => 'Mittel', 'hard' => 'Aufwendig', _ => value };

  Future<void> editRecipe() async {
    if (recipe == null || working) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ManualRecipePage(initialRecipe: recipe)),
    );
    if (changed == true && mounted) await load();
  }

  Future<void> selectPersonalToday() async {
    if (working) return;
    setState(() => working = true);
    try {
      await personalToday.selectRecipeForToday(widget.recipeId, servings: servings);
      // Notify an already-mounted TodayPage immediately. Navigation and
      // Realtime remain fallback paths, but the current page no longer needs
      // to wait for either one to reflect the successful selection.
      await widget.onTodayPlanChanged?.call();
      if (!mounted) return;
      final openToday = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Für heute festgelegt'),
          content: const Text('Das Rezept ist jetzt dein persönlicher Plan für heute. Die persönliche Einkaufsliste wurde vorbereitet.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hier bleiben')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Heute öffnen')),
          ],
        ),
      );
      if (openToday == true && mounted) {
        if (widget.onNavigateToToday != null) {
          // Close this detail route first. The AppShell callback then only
          // selects the Today tab instead of trying to remove this route
          // while its async callback is still executing.
          final navigateToToday = widget.onNavigateToToday!;
          Navigator.pop(context);
          navigateToToday();
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TodayPage()));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> markCooked() async {
    if (!widget.canMarkCooked || working) return;
    try {
      final today = await personalToday.todayPlan();
      if (today == null || !today.isRecipe || today.recipeId != widget.recipeId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dieses Rezept ist nicht mehr für heute eingeplant.')),
          );
        }
        return;
      }
      setState(() => working = true);
      final updated = await personalToday.updateStatus(today.id, 'cooked');
      if (!updated) throw StateError('Das Rezept konnte nicht als gekocht markiert werden.');
      if (!mounted) return;
      setState(() {
        cookedMarked = true;
        personalTodaySelected = false;
      });
      await widget.onTodayPlanChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezept als gekocht markiert.')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> manageRecipeImage() async {
    if (recipe == null || working) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(recipe!.imageUrl?.trim().isNotEmpty == true ? 'Bild ersetzen' : 'Bild aus Galerie wählen'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Foto aufnehmen'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            if (recipe!.imageUrl?.trim().isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Bild entfernen'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    setState(() => working = true);
    try {
      final imageService = RecipeImageService();
      if (action == 'delete') {
        await repo.removeRecipeImage(widget.recipeId);
        if (mounted) {
          setState(() {
            recipe = Recipe(
              id: recipe!.id, name: recipe!.name, description: recipe!.description, servings: recipe!.servings,
              prepTimeMinutes: recipe!.prepTimeMinutes, cookTimeMinutes: recipe!.cookTimeMinutes, difficulty: recipe!.difficulty,
              instructions: recipe!.instructions, ingredients: recipe!.ingredients, imageUrl: null, imagePath: null,
              createdBy: recipe!.createdBy, savedBy: recipe!.savedBy, savedAt: recipe!.savedAt, updatedAt: recipe!.updatedAt,
            );
          });
        }
        return;
      }
      final source = action == 'camera' ? ImageSource.camera : ImageSource.gallery;
      final file = await imageService.pickImage(source: source);
      if (file == null || !mounted) return;
      final upload = await imageService.upload(recipeId: widget.recipeId, file: file);
      final updated = await repo.setRecipeImage(widget.recipeId, upload);
      if (mounted) setState(() => recipe = updated);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> exportRecipe() async {
    if (recipe == null || working) return;
    setState(() => working = true);
    try {
      final saved = await const TogetherRecipeFileService().saveRecipe(recipe!, servings: servings);
      if (!mounted || !saved) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezeptdatei gespeichert.')),
      );
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> removeFromCollection() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rezept aus deiner Sammlung entfernen?'),
        content: const Text('Das Rezept wird aus deiner Sammlung entfernt. Ein gespeichertes Rezept der verbundenen Person oder ein aktiver Plan schützt das Rezept vor dem endgültigen Löschen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => working = true);
    try {
      final removed = await repo.removeRecipeFromCollection(widget.recipeId);
      if (!removed) {
        if (mounted) {
          setState(() => working = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Das Rezept bleibt erhalten, weil es noch gespeichert oder für heute eingeplant ist.'),
            ),
          );
        }
        return;
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) { setState(() => working = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e)))); }
    }
  }

  @override Widget build(BuildContext context) {
    if (loading) return const TogetherScaffold(backgroundType: TogetherBackgroundType.recipeDetail, respectTopSafeArea: true, topSafeAreaColor: AppDesign.background, appBar: const TogetherAppBar(title: Text('Rezept'), backgroundColor: Color(0xF7FFFBF7), systemOverlayStyle: SystemUiOverlayStyle.dark), body: Center(child: CircularProgressIndicator()));
    if (loadError != null) return TogetherScaffold(backgroundType: TogetherBackgroundType.recipeDetail, respectTopSafeArea: true, topSafeAreaColor: AppDesign.background, appBar: const TogetherAppBar(title: Text('Rezept'), backgroundColor: Color(0xF7FFFBF7), systemOverlayStyle: SystemUiOverlayStyle.dark), body: AppErrorView(error: loadError!, onRetry: load));
    if (recipe == null) return TogetherScaffold(backgroundType: TogetherBackgroundType.recipeDetail, respectTopSafeArea: true, topSafeAreaColor: AppDesign.background, appBar: const TogetherAppBar(title: Text('Rezept'), backgroundColor: Color(0xF7FFFBF7), systemOverlayStyle: SystemUiOverlayStyle.dark), body: const _RecipeErrorState());
    final ingredients = recipe!.ingredients;
    final steps = recipe!.instructions;
    final total = recipe!.prepTimeMinutes + recipe!.cookTimeMinutes;

    return TogetherScaffold(backgroundType: TogetherBackgroundType.recipeDetail, respectTopSafeArea: true, topSafeAreaColor: AppDesign.background,
      appBar: TogetherAppBar(
        title: const Text('Rezept'),
        backgroundColor: const Color(0xF7FFFBF7),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          IconButton(
            tooltip: 'Rezeptdatei speichern',
            onPressed: working ? null : exportRecipe,
            icon: const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            tooltip: 'Rezeptbild verwalten',
            onPressed: working ? null : manageRecipeImage,
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
          IconButton(
            tooltip: 'Rezept bearbeiten',
            onPressed: working ? null : editRecipe,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Rezept aus Sammlung löschen',
            onPressed: working ? null : removeFromCollection,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppDesign.peachSurface, Color(0xFFFFF3E8)],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (personalTodaySelected) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppDesign.secondarySurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Für heute ausgewählt',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    recipe!.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MetaPill(icon: Icons.timer_outlined, label: '$total Min.'),
                    MetaPill(icon: Icons.bar_chart_outlined, label: difficulty(recipe!.difficulty)),
                  ],
                ),
              ],
            ),
          ),
          if (recipe!.imageUrl?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                recipe!.imageUrl!,
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 230,
                  child: Center(child: Icon(Icons.broken_image_outlined, size: 42)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          AppSurface(
            color: AppDesign.background.withValues(alpha: .94),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Text(recipe!.description, style: Theme.of(context).textTheme.bodyLarge),
          ),
          const SizedBox(height: 14),
          AppSurface(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Personen', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Eine Person weniger',
                  onPressed: servings <= 1 || working ? null : () => setState(() => servings--),
                  icon: const Icon(Icons.remove_rounded),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('$servings', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  tooltip: 'Eine Person mehr',
                  onPressed: servings >= 12 || working ? null : () => setState(() => servings++),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppSurface(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              initiallyExpanded: false,
              onExpansionChanged: (expanded) => setState(() => ingredientsExpanded = expanded),
              title: const Text('Zutaten', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${ingredients.length} Zutaten'),
              trailing: Icon(ingredientsExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                ..._groupIngredients(ingredients).expand((group) => [
                  if (group.$1 != null) Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(group.$1!, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  ...group.$2.map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 7),
                          child: Icon(Icons.circle, size: 7, color: AppDesign.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${i.isQualitative ? '' : '${formatQuantity(scaled(i.quantity))} '}${i.unit} ${i.name}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  )),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppSurface(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              initiallyExpanded: false,
              onExpansionChanged: (expanded) => setState(() => preparationExpanded = expanded),
              title: const Text('Zubereitung', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${steps.length} Schritte'),
              trailing: Icon(preparationExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                if (steps.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: completedSteps.length / steps.length,
                      minHeight: 7,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ...List.generate(steps.length, (i) {
                  final done = completedSteps.contains(i);
                  final nextStep = i == completedSteps.length;
                  final canToggle = personalTodaySelected &&
                      (done && i == completedSteps.length - 1) ||
                      (personalTodaySelected && !done && nextStep);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: done ? AppDesign.secondarySurface : AppDesign.surface,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: working || !canToggle
                            ? null
                            : () => setState(() {
                                  if (done) {
                                    completedSteps.remove(i);
                                  } else {
                                    completedSteps.add(i);
                                  }
                                }),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: done ? AppDesign.secondarySurface : AppDesign.divider,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: done ? AppDesign.primary : AppDesign.softSurface,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: done
                                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 19)
                                      : Text(
                                          '${i + 1}',
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  steps[i].toString(),
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        decoration: done ? TextDecoration.lineThrough : null,
                                        color: done ? AppDesign.secondaryText : AppDesign.text,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                if (widget.canMarkCooked && steps.isNotEmpty && completedSteps.contains(steps.length - 1)) ...[
                  const SizedBox(height: 2),
                  SizedBox(
                    width: double.infinity,
                    child: cookedMarked
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppDesign.secondarySurface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Als gekocht markiert', style: TextStyle(fontWeight: FontWeight.w800)),
                              ],
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: working ? null : markCooked,
                            icon: const Icon(Icons.check_circle_outline_rounded),
                            label: const Text('Als gekocht markieren'),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: AppDesign.surface,
            border: const Border(top: BorderSide(color: AppDesign.divider)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: working ? null : selectPersonalToday,
                        icon: const Icon(Icons.today_rounded),
                        label: Text(
                          working
                              ? 'Für heute vorbereiten …'
                              : 'Für heute festlegen',
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

class _RecipeErrorState extends StatelessWidget {
  const _RecipeErrorState();
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.restaurant_menu_outlined, size: 56), const SizedBox(height: 16), Text('Rezept konnte nicht geladen werden', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center), const SizedBox(height: 8), const Text('Bitte versuche es noch einmal.', textAlign: TextAlign.center)])));
}
