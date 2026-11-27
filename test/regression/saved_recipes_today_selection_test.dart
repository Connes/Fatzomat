import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recipe selection uses the same library cards, filters and search UI', () {
    final source = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();
    final buildStart = source.indexOf('Widget build(BuildContext context)', source.indexOf('class SavedRecipesPageState'));
    final build = source.substring(buildStart);

    expect(source, contains("Key('saved-recipe-select-today-\${recipe.id}')"));
    expect(source, contains('selectionActive'));
    expect(source, contains("label: const Text('Auswählen')"));
    expect(source, contains("tooltip: 'Rezepte nach Hauptzutat filtern'"));
    expect(source, contains("tooltip: 'Nach Rezeptart filtern'"));
    expect(source, contains("hintText: 'Rezepte suchen'"));
    expect(source, contains('_RecipeCardImage('));
    expect(source, contains('recipe.category'));
    expect(source, contains('...recipe.foodTags'));

    expect(build, contains('body: loading'));
    expect(build, contains('CircularProgressIndicator()'));
    expect(build, contains('visibleRecipes.isEmpty'));
    expect(build, isNot(contains('if (selectionActive)')));
    expect(build, contains('selectionActive'));
  });
}
