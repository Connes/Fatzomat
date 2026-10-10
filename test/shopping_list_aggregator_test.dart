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

  test('normalizes repeated whitespace in the displayed aggregate name', () {
    final rows = aggregator.aggregate([
      item(id: 'a', name: '  Rote   Zwiebel ', quantity: 1, unit: 'Stück'),
      item(id: 'b', name: 'rote zwiebel', quantity: 2, unit: 'Stück'),
    ]);

    expect(rows, hasLength(1));
    expect(rows.single.name, 'Rote Zwiebel');
  });

  test('normalizes whitespace around food IDs before grouping', () {
    final rows = aggregator.aggregate([
      item(id: 'a', name: 'Tomate', quantity: 2, unit: 'Stück', foodId: ' food-1 '),
      item(id: 'b', name: 'Tomaten', quantity: 3, unit: 'Stück', foodId: 'food-1'),
    ]);

    expect(rows, hasLength(1));
    expect(rows.single.quantity, 5);
    expect(rows.single.sources.map((row) => row.id), containsAll(['a', 'b']));
  });

  test('normalizes unit aliases with surrounding whitespace', () {
    final rows = aggregator.aggregate([
      item(id: 'a', name: 'Mehl', quantity: 1, unit: ' KG '),
      item(id: 'b', name: 'mehl', quantity: 250, unit: ' g '),
      item(id: 'c', name: 'Milch', quantity: 1, unit: ' Liter '),
      item(id: 'd', name: 'Milch', quantity: 250, unit: ' ml '),
    ]);

    expect(rows, hasLength(2));
    final flour = rows.singleWhere((row) => row.name.toLowerCase() == 'mehl');
    final milk = rows.singleWhere((row) => row.name.toLowerCase() == 'milch');
    expect(flour.quantity, 1.25);
    expect(flour.unit, 'kg');
    expect(milk.quantity, 1.25);
    expect(milk.unit, 'l');
  });

  test('normalizes common German unit aliases', () {
    final rows = aggregator.aggregate([
      item(id: 'a', name: 'Äpfel', quantity: 2, unit: 'Stk'),
      item(id: 'b', name: 'äpfel', quantity: 3, unit: ' Stück '),
      item(id: 'c', name: 'Öl', quantity: 1, unit: 'Esslöffel'),
      item(id: 'd', name: 'öl', quantity: 2, unit: 'EL'),
    ]);

    expect(rows, hasLength(2));
    final apples = rows.singleWhere((row) => row.name.toLowerCase() == 'äpfel');
    final oil = rows.singleWhere((row) => row.name.toLowerCase() == 'öl');
    expect(apples.quantity, 5);
    expect(apples.unit, 'Stück');
    expect(oil.quantity, 3);
    expect(oil.unit, 'EL');
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

  test('keeps separate rows with blank names instead of merging them', () {
    final rows = aggregator.aggregate([
      item(id: 'a', name: ' ', quantity: 1, unit: 'Stück'),
      item(id: 'b', name: '', quantity: 2, unit: 'Stück'),
    ]);

    expect(rows, hasLength(2));
    expect(rows.map((row) => row.sources.single.id), containsAll(['a', 'b']));
    expect(rows.map((row) => row.name), containsAll([
      'Unbenannter Artikel (a)',
      'Unbenannter Artikel (b)',
    ]));
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
