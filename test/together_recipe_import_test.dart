import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/recipe.dart';
import 'package:food_app_mvp/data/models/together_recipe_importer.dart';

void main() {
  const importer = TogetherRecipeImporter();

  test('imports together_recipe v1', () {
    final recipe = importer.parse(jsonEncode({
      'format': 'together_recipe',
      'version': 1,
      'recipe': {
        'title': 'Kartoffelgratin',
        'description': 'Einfaches Gratin',
        'servings': 4,
        'prep_time_minutes': 10,
        'cook_time_minutes': 45,
        'difficulty': 'Einfach',
        'ingredients': [
          {'name': 'Kartoffeln', 'amount': 800, 'unit': 'g'},
          {'name': 'Sahne', 'amount': 200, 'unit': 'ml'},
        ],
        'steps': ['Kartoffeln schneiden.', 'Backen.'],
      },
    }));

    expect(recipe.name, 'Kartoffelgratin');
    expect(recipe.servings, 4);
    expect(recipe.ingredients, hasLength(2));
    expect(recipe.ingredients.first.quantity, 800);
    expect(recipe.instructions, ['Kartoffeln schneiden.', 'Backen.']);
  });

  test('normalizes piece units to an empty unit', () {
    final recipe = importer.parse(jsonEncode({
      'format': 'together_recipe',
      'version': 1,
      'recipe': {
        'title': 'Zwiebelpfanne',
        'ingredients': [
          {'name': 'Zwiebel', 'amount': 1, 'unit': 'Stück'},
          {'name': 'Ei', 'amount': 2, 'unit': 'Stk.'},
          {'name': 'Mehl', 'amount': 200, 'unit': 'g'},
        ],
        'steps': ['Kochen.'],
      },
    }));

    expect(recipe.ingredients[0].unit, '');
    expect(recipe.ingredients[1].unit, '');
    expect(recipe.ingredients[2].unit, 'g');
  });

  test('accepts null amount for qualitative ingredients', () {
    final recipe = importer.parse(jsonEncode({
      'format': 'together_recipe',
      'version': 1,
      'recipe': {
        'title': 'Rind mit Gemüse',
        'ingredients': [
          {'name': 'Rindfleisch', 'amount': 300, 'unit': 'g'},
          {'name': 'Salz', 'amount': null, 'unit': 'Prise'},
        ],
        'steps': ['Braten.', 'Würzen.'],
      },
    }));

    expect(recipe.ingredients.last.quantity, 1);
    expect(recipe.ingredients.last.unit, 'Prise');
  });

  test('rejects missing amount', () {
    expect(
      () => importer.parse(jsonEncode({
        'format': 'together_recipe',
        'version': 1,
        'recipe': {
          'title': 'Ohne Menge',
          'ingredients': [
            {'name': 'Salz', 'unit': 'Prise'},
          ],
          'steps': ['Würzen.'],
        },
      })),
      throwsA(isA<TogetherRecipeImportException>()),
    );
  });

  test('rejects oversized recipes', () {
    final ingredients = List.generate(51, (index) => {
      'name': 'Zutat $index',
      'amount': 1,
      'unit': 'Stück',
    });

    expect(
      () => importer.parse(jsonEncode({
        'format': 'together_recipe',
        'version': 1,
        'recipe': {
          'title': 'Zu groß',
          'ingredients': ingredients,
          'steps': ['Kochen.'],
        },
      })),
      throwsA(isA<TogetherRecipeImportException>()),
    );
  });

  test('rejects foreign format', () {
    expect(
      () => importer.parse('{"format":"other","version":1,"recipe":{}}'),
      throwsA(isA<TogetherRecipeImportException>()),
    );
  });

  test('rejects invalid json', () {
    expect(
      () => importer.parse('{not-json}'),
      throwsA(isA<TogetherRecipeImportException>()),
    );
  });

  test('recipe exports as together_recipe v1', () {
    const recipe = Recipe(
      name: 'Test',
      description: '',
      servings: 2,
      prepTimeMinutes: 5,
      cookTimeMinutes: 10,
      difficulty: 'Einfach',
      instructions: ['Kochen.'],
      ingredients: [
        RecipeIngredient(name: 'Nudeln', quantity: 200, unit: 'g'),
      ],
    );

    final json = recipe.toTogetherRecipeJson();
    expect(json['format'], 'together_recipe');
    expect(json['version'], 1);
    expect((json['recipe'] as Map)['title'], 'Test');
  });

  test('imports optional image URL without requiring it', () {
    const source = '''{
      "format":"together_recipe",
      "version":1,
      "recipe":{
        "title":"Pasta",
        "description":"Test",
        "servings":2,
        "prep_time_minutes":5,
        "cook_time_minutes":10,
        "difficulty":"Einfach",
        "ingredients":[{"name":"Pasta","amount":200,"unit":"g"}],
        "steps":["Kochen"],
        "image_url":"https://example.com/pasta.jpg"
      }
    }''';
  
    final recipe = const TogetherRecipeImporter().parse(source);
    expect(recipe.imageUrl, 'https://example.com/pasta.jpg');
    expect(recipe.imagePath, isNull);
  });
  
  test('recipe without image remains valid', () {
    const source = '''{
      "format":"together_recipe",
      "version":1,
      "recipe":{
        "title":"Salat",
        "servings":2,
        "ingredients":[{"name":"Tomate","amount":1,"unit":""}],
        "steps":["Mischen"]
      }
    }''';
  
    final recipe = const TogetherRecipeImporter().parse(source);
    expect(recipe.imageUrl, isNull);
    expect(recipe.imagePath, isNull);
  });
}
