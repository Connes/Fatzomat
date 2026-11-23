import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/recipe.dart';
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
  test('latest recipe RPC migration keeps both amount and unit optional', () {
    final migration = File(
      'supabase/migrations/20261123175448_allow_optional_recipe_ingredient_units_after_type_migrations.sql',
    );
    expect(migration.existsSync(), isTrue);
    final sql = migration.readAsStringSync();
    expect(sql, contains('create or replace function public.create_shared_recipe'));
    expect(sql, contains('create or replace function public.update_shared_recipe'));
    expect(sql, contains("ingredient_quantity := coalesce("));
    expect(sql, contains("      1"));
    expect(sql, isNot(contains('Eine Zutat benötigt eine Einheit.')));
    expect(sql, contains("if ingredient_name = '' then raise exception 'Eine Zutat benötigt einen Namen.'; end if;"));
  });

  test('imported ingredient without an amount stays quantity-optional with a unit', () {
    const importer = TogetherRecipeImporter();
    final recipe = importer.parse(jsonEncode({
      'format': 'together_recipe',
      'version': 1,
      'recipe': {
        'title': 'Teig',
        'ingredients': [
          {'name': 'Mehl', 'unit': 'g'},
        ],
        'steps': ['Mischen'],
      },
    }));

    expect(recipe.ingredients.single.unit, 'g');
    expect(recipe.ingredients.single.quantityIsOptional, isTrue);
    expect(recipe.ingredients.single.hidesQuantity, isTrue);
  });

  test('optional amount stays hidden independently from its unit', () {
    const ingredient = RecipeIngredient(
      name: 'Mehl',
      quantity: 1,
      unit: 'g',
      quantityIsOptional: true,
    );

    expect(ingredient.hidesQuantity, isTrue);
    final restored = RecipeIngredient.fromMap(ingredient.toMap());
    expect(restored.quantityIsOptional, isTrue);
    expect(restored.hidesQuantity, isTrue);
    expect(restored.unit, 'g');

    final recipe = Recipe(
      name: 'Mehlteig',
      description: '',
      servings: 1,
      prepTimeMinutes: 1,
      cookTimeMinutes: 1,
      difficulty: 'Einfach',
      instructions: const ['Rühren'],
      ingredients: const [ingredient],
    );
    final exported = recipe.toTogetherRecipeJson()['recipe'] as Map<String, dynamic>;
    final exportedIngredients = exported['ingredients'] as List<dynamic>;
    expect((exportedIngredients.single as Map)['quantity_is_optional'], isTrue);
  });

  test('optional quantity flag is stored by both recipe RPCs', () {
    final migration = File(
      'supabase/migrations/20261123175448_allow_optional_recipe_ingredient_units_after_type_migrations.sql',
    ).readAsStringSync();
    expect(migration, contains('ADD COLUMN IF NOT EXISTS quantity_is_optional boolean NOT NULL DEFAULT false'));
    expect('recipe_id, food_id, name, quantity, unit,\\n      is_user_selected, is_additional, is_qualitative, quantity_is_optional, section'.allMatches(migration).length, 2);
    expect(migration, contains("coalesce((item->>'quantity_is_optional')::boolean,false)"));
  });

}
