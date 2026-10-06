import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V86 keeps the saved recipe overflow menu focused on recipe actions', () {
    final source = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();

    expect(source, contains("if (value == 'edit') editRecipe(recipe);"));
    expect(source, contains("if (value == 'delete') deleteRecipe(recipe);"));
    expect(source, contains("if (value == 'share') shareRecipe(recipe);"));
    expect(source, contains("PopupMenuItem(value: 'edit', child: Text('Rezept bearbeiten'))"));
    expect(source, contains("PopupMenuItem(value: 'delete', child: Text('Rezept löschen'))"));
    expect(source, contains("PopupMenuItem(value: 'share', child: Text('Rezept teilen'))"));

    expect(source, isNot(contains("PopupMenuItem(value: 'today'")));
    expect(source, isNot(contains("PopupMenuItem(value: 'shopping'")));
    expect(source, isNot(contains("if (value == 'today') selectRecipeForToday(recipe);")));
    expect(source, isNot(contains("if (value == 'shopping') addRecipeToShoppingList(recipe);")));

    expect(source, contains("import 'package:share_plus/share_plus.dart';"));
    expect(source, contains('Future<void> shareRecipe(Recipe recipe) async'));
    expect(source, contains('SharePlus.instance.share('));
  });
}
