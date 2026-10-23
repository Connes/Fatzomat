import '../../data/models/food.dart';
import '../../data/models/recipe.dart';

/// Matches generated recipe ingredients against the user's explicitly disliked
/// foods. This is a conservative guard, not a substitute for prompt rules.
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
      final ingredientName = _normalize(ingredient.name);
      final found = disliked.any((food) {
        final terms = <String>{
          food.name,
          ...food.aliases,
          ...food.searchTerms,
        }.map(_normalize).where((term) => term.length >= 3);
        return terms.any((term) =>
            ingredientName == term ||
            ingredientName.contains(term) ||
            (term.length >= 5 && term.contains(ingredientName)));
      });
      if (found && !matches.contains(ingredient.name)) {
        matches.add(ingredient.name);
      }
    }
    return matches;
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9äöüß]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}
