import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V84 retains shopping list editing, sync and completed cleanup', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final entry = File('lib/features/shared/shopping_list_page.dart').readAsStringSync();

    expect(pubspec, contains('version: 1.13.46+262'));
    expect(source, contains('class ShoppingPage'));
    expect(source, contains("table: 'shopping_items'"));
    expect(source, contains('Artikel hinzufügen'));
    expect(source, contains('Artikel bearbeiten'));
    expect(source, contains('setShoppingChecked'));
    expect(source, contains('deleteShoppingItem'));
    expect(source, contains('clearCompleted'));
    expect(source, isNot(contains('Erledigte Artikel löschen?')));
    expect(source, contains('NOCH OFFEN'));
    expect(source, contains('ERLEDIGT'));
    expect(source, contains('Manuell hinzugefügt'));
    expect(source, contains('onTap: null'));
    expect(source, contains("PopupMenuItem(value: 'edit', child: Text('Bearbeiten'))"));
    expect(source, contains("PopupMenuItem(value: 'delete', child: Text('Löschen'))"));
    expect(source, contains('widget.servings'));
    expect(source, contains('widget.recipeName'));
    expect(source, isNot(contains('Rezeptmengen werden bei einer Änderung der Personenzahl automatisch aktualisiert.')));
    expect(source, isNot(contains('widget.recipeName,\n                          style: theme.textTheme.headlineSmall')));
    expect(entry, contains('ShoppingPage('));
    expect(entry, contains('shared: false'));
    expect(entry, contains("personal?.status == 'cooked' || personal?.isRecipe != true ? null : personal"));
    expect(source, contains('controller.dispose();'));
    expect(source, isNot(contains('controller.removeListener(_syncController)')));
  });


  test('V85 exposes a dedicated shopping entry point for single and connected modes', () {
    final shell = File('lib/core/app_shell.dart').readAsStringSync();
    final entry = File('lib/features/shared/shopping_list_page.dart').readAsStringSync();
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();
    final collaboration = File('lib/data/repositories/collaboration_repository.dart').readAsStringSync();
    final savedRecipes = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();

    expect(shell, contains("label: 'Einkauf'"));
    expect(shell, contains('ShoppingListPage'));
    expect(entry, contains('connection?.isConnected == true'));
    expect(entry, contains('currentSharedRecipePlan()'));
    expect(entry, contains('shared: true'));
    expect(entry, contains('shared: false'));
    expect(today, contains('widget.shared'));
    expect(today, contains('collaborationRepo.shoppingItems(widget.planId)'));
    expect(today, contains("column: widget.shared ? 'shared_recipe_plan_id' : 'personal_today_plan_id'"));
    expect(collaboration, contains('Future<Map<String, dynamic>?> currentSharedRecipePlan()'));
    expect(savedRecipes, contains('collaboration.shareRecipeForToday'));
    expect(savedRecipes, contains('Gemeinsames Rezept hinzugefügt'));
  });

  test('V86 zeigt persönliche Einkaufsliste nur für Rezeptentscheidungen', () {
    final entry = File('lib/features/shared/shopping_list_page.dart').readAsStringSync();
    final todayPlan = File('lib/data/models/today_plan.dart').readAsStringSync();
    final migration = File('supabase/migrations/20261008190000_recipe_only_personal_shopping.sql').readAsStringSync();

    expect(entry, contains("personal?.status == 'cooked' || personal?.isRecipe != true ? null : personal"));
    expect(todayPlan, contains("bool get isRecipe => decisionType == 'recipe' && recipeId != null;"));
    expect(migration, contains("p.decision_type = 'recipe'"));
    expect(migration, contains("p.recipe_id is not null"));
    expect(migration, contains('shopping personal insert'));
  });

  test('multi-day aggregated item updates prevent concurrent toggles and unlock on failure', () {
    final page = File('lib/features/shared/multi_day_shopping_list_page.dart').readAsStringSync();

    expect(page, contains("if (_updatingItems.contains(item.key) || !mounted) return;"));
    expect(page, contains("setState(() => _updatingItems.add(item.key));"));
    expect(page, contains("finally {\n      if (mounted) setState(() => _updatingItems.remove(item.key));"));
    expect(page, contains("onChanged: _updatingItems.contains(item.key)"));
    expect(page, contains('child: CircularProgressIndicator(strokeWidth: 2)'));
    expect(page, contains("await load(showLoading: false);\n      if (mounted)"));
  });

}
