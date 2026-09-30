import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/core/food_mode.dart';
import 'package:food_app_mvp/core/services/personalized_decision_service.dart';
import 'package:food_app_mvp/data/models/food.dart';
import 'package:food_app_mvp/data/models/recipe.dart';

Recipe recipe(String name) => Recipe(
      name: name,
      description: '',
      servings: 2,
      prepTimeMinutes: 10,
      cookTimeMinutes: 20,
      difficulty: 'easy',
      instructions: const ['Schneiden', 'Kochen'],
      ingredients: const [],
    );

void main() {
  test('personalized surprise prefers cooking when recipes exist', () {
    final decision = PersonalizedDecisionService.decide(
      seed: 0,
      savedRecipes: [recipe('Lieblings-Curry'), recipe('Pasta'), recipe('Tacos')],
      preferences: {'huhn': 'like', 'pilze': 'dislike'},
      foods: const [
        Food(id: 'huhn', name: 'Huhn', category: 'Fleisch'),
        Food(id: 'pilze', name: 'Pilze', category: 'Gemüse'),
      ],
    );
    expect(decision.mode, FoodMode.cook);
    expect(decision.choice, isNotEmpty);
    expect(decision.reason, contains('gesammelt'));
  });

  test('mode-specific surprise avoids a disliked choice', () {
    final decision = PersonalizedDecisionService.decideForMode(
      mode: FoodMode.cook,
      seed: 2,
      savedRecipes: const [],
      preferences: {'1': 'dislike'},
      foods: const [Food(id: '1', name: 'Fisch', category: 'Fisch')],
    );
    expect(decision.choice, isNot('Fisch'));
  });
}
