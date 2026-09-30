import '../../data/models/food.dart';

List<Food> filterFoods({
  required List<Food> foods,
  required Map<String, String> preferences,
  required String query,
  required String preferenceFilter,
  required String categoryFilter,
}) {
  final normalizedQuery = query.trim().toLowerCase();

  return foods.where((food) {
    final matchesQuery = normalizedQuery.isEmpty ||
        food.name.toLowerCase().contains(normalizedQuery) ||
        [food.name, ...food.searchTerms, ...food.aliases].any((term) => term.toLowerCase().contains(normalizedQuery));
    final preference = preferences[food.id];
    final matchesPreference = preferenceFilter == 'all' || preference == preferenceFilter;
    final matchesCategory = categoryFilter == 'Alle' || food.category == categoryFilter;
    return matchesQuery && matchesPreference && matchesCategory;
  }).toList();
}
