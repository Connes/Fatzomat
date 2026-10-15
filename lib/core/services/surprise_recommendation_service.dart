import 'dart:math';

import '../../core/food_mode.dart';
import '../../data/models/food.dart';
import '../../data/models/recipe.dart';
import 'personalized_decision_service.dart';

class SurpriseRecommendation {
  final PersonalizedDecision decision;
  final List<Recipe> recipes;

  const SurpriseRecommendation({
    required this.decision,
    this.recipes = const [],
  });

  bool get isRecipe => decision.mode == FoodMode.cook;
  bool get isRestaurant => decision.mode != FoodMode.cook;
}

class SurpriseRecommendationService {
  SurpriseRecommendationService();

  Future<SurpriseRecommendation> generate({
    required List<Recipe> savedRecipes,
    required Map<String, String> preferences,
    required List<Food> foods,
    int? seed,
  }) async {
    final decision = PersonalizedDecisionService.decide(
      savedRecipes: savedRecipes,
      preferences: preferences,
      foods: foods,
      seed: seed,
    );

    if (decision.mode == FoodMode.cook) {
      final recipes = _pickRecipes(savedRecipes, seed ?? DateTime.now().microsecondsSinceEpoch);
      return SurpriseRecommendation(decision: decision, recipes: recipes);
    }

    // Restaurant discovery has been retired. Keep the personal decision flow,
    // but do not call the removed search API. The user can choose a cuisine
    // and import a restaurant through the ChatGPT flow instead.
    return SurpriseRecommendation(decision: decision);
  }

  List<Recipe> _pickRecipes(List<Recipe> source, int seed) {
    final candidates = source.where((recipe) => recipe.id != null && recipe.name.trim().isNotEmpty).toList();
    if (candidates.length <= 3) return List.unmodifiable(candidates);
    final random = Random(seed);
    candidates.shuffle(random);
    return List.unmodifiable(candidates.take(3));
  }
}
