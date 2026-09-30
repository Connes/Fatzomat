class ShoppingItem {
  final String id;
  final String name;
  final num quantity;
  final String unit;
  final bool checked;
  final String? foodId;
  final String category;
  final String source;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.checked,
    this.foodId,
    this.category = 'Weitere Zutaten',
    this.source = 'recipe',
  });

  factory ShoppingItem.fromMap(Map<String, dynamic> map) => ShoppingItem(
        id: map['id'].toString(),
        name: map['name']?.toString() ?? '',
        quantity: map['quantity'] is num
            ? map['quantity'] as num
            : num.tryParse(map['quantity']?.toString() ?? '') ?? 0,
        unit: map['unit']?.toString() ?? '',
        checked: map['checked'] == true,
        foodId: map['food_id']?.toString(),
        category: map['foods'] is Map
            ? (map['foods']['category']?.toString() ?? 'Weitere Zutaten')
            : (map['category']?.toString() ?? 'Weitere Zutaten'),
        source: map['source']?.toString() ?? 'recipe',
      );
}
