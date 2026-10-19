import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saved recipes expose a subtle main ingredient filter with all five categories', () {
    final source = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();
    final appBar = File('lib/core/widgets/together_scaffold.dart').readAsStringSync();

    expect(source, contains("tooltip: 'Rezepte nach Hauptzutat filtern'"));
    expect(source, contains("title: const Text('Meine Rezepte')"));
    expect(appBar, contains('centerTitle: true'));
    expect(source, contains('BorderRadius.circular(20)'));
    expect(source, contains('AppDesign.secondarySurface'));
    expect(source, contains("value == 'Alle' ? 'Alle Rezepte' : value"));
    expect(source, contains("('Schwein', Icons."));
    expect(source, contains("('Rind', Icons."));
    expect(source, contains("('Huhn', Icons."));
    expect(source, contains("('Vegetarisch', Icons."));
    expect(source, contains("('Fisch', Icons."));
    expect(source, contains('mainIngredientFilter'));
    expect(source, contains('mainChoice: mainIngredientFilter'));
  });

  test('V86 keeps the saved recipe overflow menu focused on recipe actions', () {
    final source = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();

    expect(source, contains("if (value == 'edit') editRecipe(recipe);"));
    expect(source, contains("if (value == 'delete') deleteRecipe(recipe);"));
    expect(source, contains("if (value == 'share') shareRecipe(recipe);"));
    expect(source, contains("value: 'edit'"));
    expect(source, contains("title: Text('Rezept bearbeiten')"));
    expect(source, contains("value: 'delete'"));
    expect(source, contains("title: Text('Rezept löschen'"));
    expect(source, contains("value: 'share'"));
    expect(source, contains("title: Text('Rezept teilen')"));

    expect(source, isNot(contains("PopupMenuItem(value: 'today'")));
    expect(source, isNot(contains("PopupMenuItem(value: 'shopping'")));
    expect(source, isNot(contains("if (value == 'today') selectRecipeForToday(recipe);")));
    expect(source, isNot(contains("if (value == 'shopping') addRecipeToShoppingList(recipe);")));

    expect(source, contains("import 'package:share_plus/share_plus.dart';"));
    expect(source, contains('Future<void> shareRecipe(Recipe recipe) async'));
    expect(source, contains('SharePlus.instance.share('));
  });
}
