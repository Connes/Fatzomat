import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/food_mode.dart';
import '../../lib/core/services/surprise_recommendation_service.dart';
import '../../lib/data/models/food.dart';
import '../../lib/data/models/recipe.dart';

Recipe _recipe(String id) => Recipe(
      id: id,
      name: 'Rezept $id',
      description: '',
      servings: 2,
      prepTimeMinutes: 10,
      cookTimeMinutes: 15,
      difficulty: 'Einfach',
      instructions: const [],
      ingredients: const [],
    );

void main() {
  test('Überraschung Kochen liefert drei unterschiedliche Rezepte', () async {
    final service = SurpriseRecommendationService();
    final result = await service.generate(
      savedRecipes: List.generate(6, (i) => _recipe('$i')),
      preferences: const {},
      foods: const <Food>[],
      seed: 0,
    );

    expect(result.decision.mode, FoodMode.cook);
    expect(result.recipes, hasLength(3));
    expect(result.recipes.map((r) => r.id).toSet(), hasLength(3));
  });

  test('Überraschung Essen gehen bleibt ohne alte Restaurant-Suche nutzbar', () async {
    final service = SurpriseRecommendationService();
    final result = await service.generate(
      savedRecipes: List.generate(4, (i) => _recipe('$i')),
      preferences: const {},
      foods: const <Food>[],
      seed: 9,
    );

    expect(result.decision.mode, FoodMode.dineOut);
    expect(result.recipes, isEmpty);
  });

  test('Überraschung Bestellen bleibt ohne alte Restaurant-Suche nutzbar', () async {
    final service = SurpriseRecommendationService();
    final result = await service.generate(
      savedRecipes: List.generate(4, (i) => _recipe('$i')),
      preferences: const {},
      foods: const <Food>[],
      seed: 7,
    );

    expect(result.decision.mode, FoodMode.order);
    expect(result.recipes, isEmpty);
  });
}
