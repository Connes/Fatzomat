import '../../core/food_name_normalizer.dart';
import '../../data/models/food.dart';
import '../../data/models/recipe.dart';

/// Matches recipe ingredients against disliked foods using shared name normalization.
class FoodPreferenceRecipeGuard {
  const FoodPreferenceRecipeGuard._();

  static List<String> findDislikedIngredients({
    required Recipe recipe,
    required List<Food> foods,
    required Map<String, String> preferences,
  }) {
    final disliked = foods
        .where((food) => preferences[food.id] == 'dislike')
        .toList(growable: false);
    if (disliked.isEmpty) return const [];

    final matches = <String>[];
    for (final ingredient in recipe.ingredients) {
      final found = disliked.any((food) {
        final terms = <String>{food.name, ...food.aliases, ...food.searchTerms}
            .where((term) => FoodNameNormalizer.normalize(term).length >= 3);
        return terms.any((term) =>
            FoodNameNormalizer.equivalentOrContains(ingredient.name, term));
      });
      if (found && !matches.contains(ingredient.name)) matches.add(ingredient.name);
    }
    return matches;
  }
}
