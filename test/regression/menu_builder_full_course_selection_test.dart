import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('menu builder renders all three courses as editable recipe pickers', () {
    final source = File('lib/features/shared/menu_builder_page.dart').readAsStringSync();

    expect(source, contains("title: 'Hauptgericht'"));
    expect(source, contains("title: 'Vorspeise'"));
    expect(source, contains("title: 'Nachtisch'"));
    expect(source, contains("subtitle: 'Pflichtgang · kann geändert werden'"));
    expect(source, contains('_mainRecipeId'));
    expect(source, contains('_today.selectRecipeForToday('));
    expect(source, contains('_today.saveMenuCourses(planId, _courses())'));
    expect(source, contains('excludedRecipeIds'));
    expect(source, contains('if (_starterId == value) _starterId = null'));
    expect(source, contains('if (_dessertId == value) _dessertId = null'));
  });

  test('saved recipe selection offers optional courses after servings are confirmed', () {
    final source = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();
    final servingsDialog = source.indexOf('final servings = await showDialog<int>');
    final recipeSelection = source.indexOf('final planId = await personalToday.selectRecipeForToday(');
    final menuPrompt = source.indexOf('final addCourses = await _askToAddMenuCourses()');
    final menuRoute = source.indexOf('MenuBuilderPage(plan: selectedPlan, planDate: planDate)');
    final navigation = source.indexOf('final navigateToToday = widget.onNavigateToToday');

    expect(servingsDialog, isNonNegative);
    expect(recipeSelection, greaterThan(servingsDialog));
    expect(menuPrompt, greaterThan(recipeSelection));
    expect(menuRoute, greaterThan(menuPrompt));
    expect(navigation, greaterThan(menuPrompt));
    expect(source, contains('Möchtest du eine Vorspeise oder einen Nachtisch hinzufügen?'));
    expect(source, contains("child: const Text('Nein, danke')"));
    expect(source, contains("child: const Text('Menü zusammenstellen')"));
  });

  test('Today page passes the active planning date into the menu editor', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    expect(source, contains('MenuBuilderPage(plan: current, planDate: _selectedDate)'));
  });
}
