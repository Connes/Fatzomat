import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ChatGPT recipe import offers optional courses after selecting the recipe for Today', () {
    final source = File('lib/features/recipes/add_recipe_page.dart').readAsStringSync();
    final save = source.indexOf('Future<void> _save() async');
    final select = source.indexOf('final planId = await PersonalTodayRepository().selectRecipeForToday(', save);
    final prompt = source.indexOf('final addCourses = await _askToAddMenuCourses()', select);
    final editor = source.indexOf('MenuBuilderPage(', prompt);

    expect(select, isNonNegative);
    expect(prompt, greaterThan(select));
    expect(editor, greaterThan(prompt));
    expect(source, contains("title: const Text('Menü ergänzen?', textAlign: TextAlign.center)"));
  });

  test('menu prompt title is centered and both choices are left aligned vertically', () {
    for (final path in [
      'lib/features/recipes/add_recipe_page.dart',
      'lib/features/recipes/saved_recipes_page.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('actionsAlignment: MainAxisAlignment.start'));
      expect(source, contains('crossAxisAlignment: CrossAxisAlignment.start'));
      expect(source, contains("child: const Text('Nein, danke')"));
      expect(source, contains("child: const Text('Menü zusammenstellen')"));
    }
  });

  test('menu save action is pinned below the scrollable course pickers', () {
    final source = File('lib/features/shared/menu_builder_page.dart').readAsStringSync();
    expect(source, contains('Expanded(\n                  child: ListView('));
    expect(source, contains('padding: const EdgeInsets.fromLTRB(16, 8, 16, 10)'));
    expect(source, contains("label: Text(_saving ? 'Wird gespeichert …' : 'Menü speichern')"));
  });

  test('Today recipe title is centered vertically when there are no optional courses', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    expect(source, contains("(plan.isRecipe && plan.menuCourses.isEmpty)"));
    expect(source, contains('Expanded(\n              child: Center(child: _buildTitle(context))'));
  });
}
