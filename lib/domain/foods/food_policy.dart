import '../../data/models/food.dart';

/// Domain rules for food classification. Classification is based exclusively
/// on structured database taxonomy, never on display-name/category guessing.
abstract final class FoodPolicy {
  static bool isVegetarian(Food food) =>
      food.dietaryType == 'vegetarian' || food.dietaryType == 'vegan';

  static bool isVegan(Food food) => food.dietaryType == 'vegan';

  static bool isFish(Food food) => food.proteinType == 'fish';

  static bool isMeat(Food food) => food.proteinType == 'meat';

  static bool containsAllergen(Food food, String allergen) {
    final normalized = allergen.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return food.allergens.any((item) => item.trim().toLowerCase() == normalized);
  }
}
