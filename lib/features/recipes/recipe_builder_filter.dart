List<Map<String, dynamic>> filterRecipeFoods({
  required List<Map<String, dynamic>> foods,
  required String query,
  required String category,
}) {
  final normalized = query.trim().toLowerCase();
  return foods.where((food) {
    final name = (food['name'] ?? '').toString().toLowerCase();
    final foodCategory = (food['category'] ?? '').toString();
    return (normalized.isEmpty || name.contains(normalized)) &&
        (category == 'Alle' || foodCategory == category);
  }).toList();
}
