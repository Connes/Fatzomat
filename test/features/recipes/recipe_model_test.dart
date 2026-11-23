import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/recipe.dart';

void main() {
  test('Recipe parses generated recipe payload', () {
    final recipe = Recipe.fromMap({
      'id': 'r1',
      'name': 'Curry',
      'description': 'Schnell',
      'servings': 2,
      'prep_time_minutes': 10,
      'cook_time_minutes': 20,
      'difficulty': 'Einfach',
      'steps': ['Kochen'],
      'ingredients': [
        {'food_id': 'f1', 'name': 'Reis', 'quantity': 200, 'unit': 'g', 'is_user_selected': true},
      ],
    });

    expect(recipe.name, 'Curry');
    expect(recipe.ingredients.single.foodId, 'f1');
    expect(recipe.instructions.single, 'Kochen');
  });

  test('Recipe scales ingredient quantities with servings', () {
  final recipe = Recipe(
    name: 'Testgericht',
    description: '',
    servings: 2,
    prepTimeMinutes: 10,
    cookTimeMinutes: 10,
    difficulty: 'easy',
    instructions: const ['Kochen'],
    ingredients: const [
      RecipeIngredient(name: 'Reis', quantity: 200, unit: 'g'),
      RecipeIngredient(name: 'Salz', quantity: 1, unit: 'TL'),
    ],
  );

  final scaled = recipe.scaledTo(4);
  expect(scaled.servings, 4);
  expect(scaled.ingredients[0].quantity, 400);
  expect(scaled.ingredients[1].quantity, 2);
  });


  test('Recipe parses and preserves independent food tags', () {
    final recipe = Recipe.fromMap({
      'id': 'r-tags',
      'name': 'Rindergulasch',
      'description': '',
      'servings': 4,
      'prep_time_minutes': 15,
      'cook_time_minutes': 90,
      'difficulty': 'Mittel',
      'category': 'Hauptgericht',
      'food_tags': ['Rind', 'Fisch', 'unknown'],
      'instructions': ['Schmoren'],
      'ingredients': [
        {'name': 'Rinderhack', 'quantity': 500, 'unit': 'g'},
      ],
    });

    expect(recipe.category, 'Hauptgericht');
    expect(recipe.foodTags, ['Rind', 'Fisch']);
    expect(recipe.scaledTo(8).foodTags, ['Rind', 'Fisch']);
    expect(recipe.toMap()['food_tags'], ['Rind', 'Fisch']);
  });

  test('Vegetarian tag cannot coexist with meat or fish tags', () {
    final recipe = Recipe.fromMap({
      'name': 'Gemüsecurry',
      'servings': 2,
      'prep_time_minutes': 10,
      'cook_time_minutes': 20,
      'difficulty': 'Einfach',
      'food_tags': ['Vegetarisch', 'Rind'],
      'instructions': [],
      'ingredients': [],
    });

    expect(recipe.foodTags, ['Vegetarisch']);
  });
}
