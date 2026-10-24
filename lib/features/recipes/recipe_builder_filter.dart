import '../../core/food_name_normalizer.dart';

List<Map<String, dynamic>> filterRecipeFoods({
  required List<Map<String, dynamic>> foods,
  required String query,
  required String category,
}) {
  return foods.where((food) {
    final name = (food['name'] ?? '').toString();
    final aliases = (food['aliases'] is List ? food['aliases'] as List : const [])
        .map((item) => item.toString());
    final terms = [name, ...aliases];
    final matchesQuery = query.trim().isEmpty ||
        terms.any((term) => FoodNameNormalizer.matches(term, query));
    final foodCategory = (food['category'] ?? '').toString();
    return matchesQuery && (category == 'Alle' || foodCategory == category);
  }).toList();
}
