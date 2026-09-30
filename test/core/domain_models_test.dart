import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/food.dart';
import 'package:food_app_mvp/data/models/recipe.dart';

void main() {
  test('Food model maps database fields without dynamic access', () {
    final food = Food.fromMap({
      'id': 'rice', 'name': 'Reis', 'category': 'Getreide',
      'search_terms': 'basmati', 'default_unit': 'g', 'created_by': null,
    });
    expect(food.id, 'rice');
    expect(food.searchTerms, ['basmati']);
  });

  test('Recipe model retains collection metadata', () {
    final recipe = Recipe.fromMap({
      'id': 'r1', 'created_by': 'u1', '_saved_by': 'u2',
      'name': 'Curry', 'description': 'Dampf', 'servings': 2,
      'prep_time_minutes': 10, 'cook_time_minutes': 20,
      'difficulty': 'easy', 'instructions': ['Kochen'],
      'recipe_ingredients': [
        {'food_id': 'rice', 'name': 'Reis', 'quantity': 200, 'unit': 'g'},
      ],
    });
    expect(recipe.createdBy, 'u1');
    expect(recipe.savedBy, 'u2');
    expect(recipe.ingredients.single.foodId, 'rice');
  });
}
