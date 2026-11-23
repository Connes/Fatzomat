import 'package:flutter/material.dart';

import '../../core/app_design.dart';
import '../../core/app_feedback.dart';
import '../../core/error_text.dart';
import '../../core/widgets/together_background.dart';
import '../../core/widgets/together_scaffold.dart';
import '../../data/models/recipe.dart';
import '../../data/models/today_plan.dart';
import '../../data/repositories/personal_today_repository.dart';
import '../../data/repositories/recipe_repository.dart';

class MenuBuilderPage extends StatefulWidget {
  final TodayPlan plan;
  const MenuBuilderPage({super.key, required this.plan});

  @override
  State<MenuBuilderPage> createState() => _MenuBuilderPageState();
}

class _MenuBuilderPageState extends State<MenuBuilderPage> {
  final _recipes = RecipeRepository();
  final _today = PersonalTodayRepository();
  List<Recipe> _available = const [];
  String? _starterId;
  String? _dessertId;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final course in widget.plan.menuCourses) {
      final id = course['recipe_id']?.toString();
      if (course['course'] == 'starter') _starterId = id;
      if (course['course'] == 'dessert') _dessertId = id;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _recipes.savedRecipeModels();
      if (!mounted) return;
      setState(() { _available = rows; _loading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppFeedback.showSnackBar(context, SnackBar(content: Text(friendlyError(error))));
    }
  }

  Recipe? _recipe(String? id) {
    for (final recipe in _available) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  List<Map<String, dynamic>> _courses() {
    final result = <Map<String, dynamic>>[];
    for (final entry in <(String, Recipe?)>[
      ('starter', _recipe(_starterId)),
      ('dessert', _recipe(_dessertId)),
    ]) {
      final recipe = entry.$2;
      if (recipe == null || recipe.id == null) continue;
      result.add({
        'course': entry.$1,
        'recipe_id': recipe.id,
        'name': recipe.name,
        'image_url': recipe.imageUrl,
        'prep_time_minutes': recipe.prepTimeMinutes,
        'cook_time_minutes': recipe.cookTimeMinutes,
      });
    }
    return result;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _today.saveMenuCourses(widget.plan.id, _courses());
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) AppFeedback.showSnackBar(context, SnackBar(content: Text(friendlyError(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _picker({
    required String title,
    required String subtitle,
    required String? value,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    final options = _available.where((recipe) => recipe.id != widget.plan.recipeId).toList();
    return Card(
      color: AppDesign.surface.withValues(alpha: 0.97),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: AppDesign.iconGold, size: 25),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppDesign.secondaryText)),
            ])),
            if (value != null) IconButton(tooltip: 'Gang entfernen', onPressed: () => onChanged(null), icon: const Icon(Icons.close_rounded)),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Rezept auswählen', border: OutlineInputBorder()),
            hint: const Text('Kein Gang ausgewählt'),
            items: options.map((recipe) => DropdownMenuItem<String>(
              value: recipe.id,
              child: Text(recipe.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: onChanged,
          ),
          if (options.isEmpty)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text('Noch keine weiteren gespeicherten Rezepte vorhanden.', style: Theme.of(context).textTheme.bodySmall)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => TogetherScaffold(
    backgroundType: TogetherBackgroundType.recipes,
    appBar: const TogetherAppBar(title: Text('Menü zusammenstellen')),
    body: SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
              Card(
                color: AppDesign.surface.withValues(alpha: 0.97),
                child: ListTile(
                  leading: const Icon(Icons.restaurant_menu_rounded, color: AppDesign.iconGold, size: 30),
                  title: const Text('Hauptgericht', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(widget.plan.name),
                  trailing: const Icon(Icons.check_circle_rounded, color: AppDesign.primaryDark),
                ),
              ),
              const SizedBox(height: 12),
              _picker(title: 'Vorspeise', subtitle: 'Optional · kann leer bleiben', value: _starterId, icon: Icons.soup_kitchen_rounded, onChanged: (value) => setState(() => _starterId = value)),
              const SizedBox(height: 10),
              _picker(title: 'Nachtisch', subtitle: 'Optional · kann leer bleiben', value: _dessertId, icon: Icons.cake_rounded, onChanged: (value) => setState(() => _dessertId = value)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Wird gespeichert …' : 'Menü speichern'),
                style: FilledButton.styleFrom(backgroundColor: AppDesign.primaryDark, minimumSize: const Size.fromHeight(54)),
              ),
            ]),
    ),
  );
}
