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
    expect(source, contains("('Vegetarisch', Icons."));
    expect(source, contains("('Fisch', Icons."));
    expect(source, contains('mainIngredientFilter'));
    expect(source, contains('mainChoice: mainIngredientFilter'));
  });

  test('V86 keeps the saved recipe overflow menu focused on recipe actions', () {
    final source = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();

    expect(source, contains("tooltip: 'Rezept bearbeiten'"));
    expect(source, contains("tooltip: 'Rezept löschen'"));
    expect(source, contains("tooltip: 'Rezept teilen'"));
    expect(source, contains("onPressed: () => editRecipe(recipe)"));
    expect(source, contains("onPressed: () => deleteRecipe(recipe)"));
    expect(source, contains("onPressed: () => shareRecipe(recipe)"));
    expect(source, contains("Icons.edit_outlined, color: AppDesign.iconGold"));
    expect(source, contains("Icons.delete_outline_rounded, color: AppDesign.error"));
    expect(source, contains("Icons.share_outlined, color: AppDesign.iconGold"));
    expect(source, isNot(contains("tooltip: 'Rezeptoptionen'")));

    expect(source, contains("import 'package:share_plus/share_plus.dart';"));
    expect(source, contains('Future<void> shareRecipe(Recipe recipe) async'));
    expect(source, contains('SharePlus.instance.share('));
  });
}
