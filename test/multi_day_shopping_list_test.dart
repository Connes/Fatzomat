import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/shopping_item.dart';
import 'package:food_app_mvp/data/services/shopping_list_aggregator.dart';

void main() {
  test('shopping item retains its source plan ID for day filtering', () {
    final item = ShoppingItem.fromMap({
      'id': 'item-1',
      'name': 'Tomaten',
      'quantity': 2,
      'unit': 'Stück',
      'checked': false,
      'personal_today_plan_id': 'plan-tomorrow',
    });

    expect(item.planId, 'plan-tomorrow');
  });

  test('same ingredient from separate plans aggregates and preserves source IDs', () {
    const aggregator = ShoppingListAggregator();
    final result = aggregator.aggregate([
      const ShoppingItem(
        id: 'today-item',
        name: 'Mehl',
        quantity: 500,
        unit: 'g',
        checked: false,
        planId: 'today-plan',
      ),
      const ShoppingItem(
        id: 'tomorrow-item',
        name: 'Mehl',
        quantity: 0.25,
        unit: 'kg',
        checked: true,
        planId: 'tomorrow-plan',
      ),
    ]);

    expect(result, hasLength(1));
    expect(result.single.quantity, 0.75);
    expect(result.single.unit, 'kg');
    expect(result.single.sources.map((item) => item.id).toSet(),
        {'today-item', 'tomorrow-item'});
    expect(result.single.checked, isFalse);
  });
}
