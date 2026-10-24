import '../../data/models/food.dart';
import '../../core/food_name_normalizer.dart';

List<Food> filterFoods({
  required List<Food> foods,
  required Map<String, String> preferences,
  required String query,
  required String preferenceFilter,
  required String categoryFilter,
}) {
  return foods.where((food) {
    final terms = [food.name, ...food.searchTerms, ...food.aliases];
    final matchesQuery = query.trim().isEmpty ||
        terms.any((term) => FoodNameNormalizer.matches(term, query));
    final preference = preferences[food.id];
    final matchesPreference = preferenceFilter == 'all' || preference == preferenceFilter;
    final matchesCategory = categoryFilter == 'Alle' || food.category == categoryFilter;
    return matchesQuery && matchesPreference && matchesCategory;
  }).toList();
}
