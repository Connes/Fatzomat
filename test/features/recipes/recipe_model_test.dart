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

}
