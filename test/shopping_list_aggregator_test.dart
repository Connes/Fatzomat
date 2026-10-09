import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/shopping_item.dart';
import 'package:food_app_mvp/data/services/shopping_list_aggregator.dart';

ShoppingItem item({
  required String id,
  required String name,
  required num quantity,
  required String unit,
  String? foodId,
  bool checked = false,
}) =>
    ShoppingItem(
      id: id,
      name: name,
      quantity: quantity,
      unit: unit,
      checked: checked,
      foodId: foodId,
    );

void main() {
  const aggregator = ShoppingListAggregator();

  test('aggregates grams and kilograms into a single mass quantity', () {
    final rows = aggregator.aggregate([
      item(id: 'a', name: 'Mehl', quantity: 500, unit: 'g'),
      item(id: 'b', name: 'mehl', quantity: 0.25, unit: 'kg'),
    ]);

    expect(rows, hasLength(1));
    expect(rows.single.quantity, 0.75);
    expect(rows.single.unit, 'kg');
    expect(rows.single.sources.map((row) => row.id), containsAll(['a', 'b']));
  });

  test('aggregates liters and milliliters', () {
    final rows = aggregator.aggregate([
      item(id: 'a', name: 'Milch', quantity: 1, unit: 'l'),
      item(id: 'b', name: 'Milch', quantity: 500, unit: 'ml'),
    ]);

    expect(rows, hasLength(1));
    expect(rows.single.quantity, 1.5);
    expect(rows.single.unit, 'l');
  });

  test('does not merge incompatible or unknown units', () {
    final rows = aggregator.aggregate([
      item(id: 'a', name: 'Zucker', quantity: 100, unit: 'g'),
      item(id: 'b', name: 'Zucker', quantity: 1, unit: 'EL'),
      item(id: 'c', name: 'Zucker', quantity: 2, unit: 'TL'),
    ]);

    expect(rows, hasLength(3));
  });

  test('aggregated row is checked only when every source is checked', () {
    final rows = aggregator.aggregate([
      item(id: 'a', name: 'Eier', quantity: 2, unit: 'Stück', checked: true),
      item(id: 'b', name: 'Eier', quantity: 3, unit: 'Stück', checked: false),
    ]);

    expect(rows, hasLength(1));
    expect(rows.single.checked, isFalse);
    expect(rows.single.sources, hasLength(2));
  });
}
