import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V84 retains shopping list editing, sync and completed cleanup', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final entry = File('lib/features/shared/shopping_list_page.dart').readAsStringSync();

    expect(pubspec, contains('version: 1.13.36+248'));
    expect(source, contains('class ShoppingPage'));
    expect(source, contains("table: 'shopping_items'"));
    expect(source, contains('Artikel hinzufügen'));
    expect(source, contains('Artikel bearbeiten'));
    expect(source, contains('setShoppingChecked'));
    expect(source, contains('deleteShoppingItem'));
    expect(source, contains('clearCompleted'));
    expect(source, contains('Erledigte Artikel löschen?'));
    expect(source, contains('NOCH OFFEN'));
    expect(source, contains('ERLEDIGT'));
    expect(source, contains('Manuell hinzugefügt'));
    expect(source, contains('widget.servings'));
    expect(source, contains('Manuelle Artikel bleiben erhalten'));
    expect(entry, contains('ShoppingPage('));
    expect(entry, contains('shared: false'));
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

}
