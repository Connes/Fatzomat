import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/together_recipe_importer.dart';

void main() {
  test('recipe import keeps piece-count ingredients unitless', () {
    const importer = TogetherRecipeImporter();
    final recipe = importer.parse(jsonEncode({
      'format': 'together_recipe',
      'version': 1,
      'recipe': {
        'title': 'Zwiebelpfanne',
        'ingredients': [
          {'name': 'Zwiebeln', 'amount': 2, 'unit': 'Stück'},
          {'name': 'Knoblauchzehen', 'amount': 3, 'unit': 'stk.'},
          {'name': 'Mehl', 'amount': 200, 'unit': 'g'},
        ],
        'steps': ['Zwiebeln schneiden.'],
      },
    }));

    expect(recipe.ingredients[0].unit, isEmpty);
    expect(recipe.ingredients[1].unit, isEmpty);
    expect(recipe.ingredients[2].unit, 'g');
  });

  test('recipe save RPC migration accepts unitless ingredients', () {
    final migrations = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('_allow_unitless_recipe_ingredients.sql'))
        .toList();
    expect(migrations, hasLength(1));

    final sql = migrations.single.readAsStringSync();
    expect(sql, contains('create or replace function public.create_shared_recipe'));
    expect(sql, contains('create or replace function public.update_shared_recipe'));
    expect(sql, isNot(contains("if ingredient_unit='' then raise exception 'Eine Zutat benötigt eine Einheit.'")));
    expect(sql, isNot(contains("ingredient_name='' or ingredient_unit='' or ingredient_quantity<=0")));
    expect(sql, contains("if ingredient_name='' then raise exception 'Eine Zutat benötigt einen Namen.'"));
  });
}
