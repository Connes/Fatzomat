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
    expect(source, contains("('Schwein', SvgPicture.asset("));
    expect(source, contains("('Rind', SvgPicture.asset("));
    expect(source, contains("('Huhn', SvgPicture.asset("));
    expect(source, contains("('Vegetarisch', const Icon("));
    expect(source, contains("('Fisch', const Icon("));
    expect(source, contains('mainIngredientFilter'));
    expect(source, contains('tooltip: \'Nach Rezeptart filtern\''));
    expect(source, contains('foodTag: mainIngredientFilter'));
    expect(source, contains('category: categoryFilter'));
    expect(source, contains('recipe.foodTags'));
  });

  test('recipe filter selection remains visible briefly and both menus share one design', () {
    final source = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();

    expect(source, contains('offset: const Offset(12, 0)'));
    expect(source, contains('Future<void>.delayed(const Duration(milliseconds: 200)'));
    expect(source, contains('if (menuContext.mounted) Navigator.of(menuContext).pop()'));
    expect(source, contains('enabled: false'));
    expect(source, contains('BorderRadius.circular(20)'));
    expect(source, contains('AppDesign.secondarySurface'));
    expect(source, contains('tooltip: \'Nach Rezeptart filtern\''));
    expect(source, contains('Future<void>.delayed(const Duration(milliseconds: 200)'));
    expect(source, contains('selectedValue.value = value'));
    expect(source, contains('highlightColor: Colors.transparent'));
  });

  test('leaving the recipes tab resets both library filters', () {
    final source = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();
    final shell = File('lib/core/app_shell.dart').readAsStringSync();

    expect(source, contains('void resetFilters()'));
    expect(source, contains('mainIngredientFilter = null;'));
    expect(source, contains('categoryFilter = null;'));
    expect(shell, contains('_resetRecipeFiltersWhenLeaving(value)'));
    expect(shell, contains('_savedRecipesKey.currentState?.resetFilters()'));
  });

  test('V86 keeps the saved recipe overflow menu focused on recipe actions', () {
    final source = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();

    expect(source, isNot(contains("tooltip: 'Rezept bearbeiten'")));
    expect(source, isNot(contains("tooltip: 'Rezept löschen'")));
    expect(source, contains("tooltip: 'Rezept teilen'"));
    expect(source, isNot(contains("onPressed: () => editRecipe(recipe)")));
    expect(source, isNot(contains("onPressed: () => deleteRecipe(recipe)")));
    expect(source, contains("onPressed: () => shareRecipe(recipe)"));
    expect(source, isNot(contains("Icons.edit_outlined, color: AppDesign.iconGold")));
    expect(source, isNot(contains("Icons.delete_outline_rounded, color: AppDesign.error")));
    expect(source, contains("Icons.share_outlined, color: AppDesign.iconGold"));
    expect(source, contains("tooltip: 'Rezept teilen'"));

    expect(source, contains("import 'package:share_plus/share_plus.dart';"));
    expect(source, contains('Future<void> shareRecipe(Recipe recipe) async'));
    expect(source, contains('SharePlus.instance.share('));
  });
}
