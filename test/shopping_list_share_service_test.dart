import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/shopping_item.dart';
import 'package:food_app_mvp/data/services/shopping_list_share_service.dart';

void main() {
  group('ShoppingListShareService', () {
    const service = ShoppingListShareService();

    test('shares only unchecked items and keeps grouped categories', () {
      final text = service.buildText(
        title: 'Einkaufsliste',
        subtitle: 'Cremige Gnocchi-Pfanne · 2 Personen',
        items: const [
          ShoppingItem(
            id: '1',
            name: 'Babyspinat',
            quantity: 200,
            unit: 'g',
            checked: false,
            category: 'Gemüse',
          ),
          ShoppingItem(
            id: '2',
            name: 'Gnocchi',
            quantity: 500,
            unit: 'g',
            checked: false,
            category: 'Teigwaren',
          ),
          ShoppingItem(
            id: '3',
            name: 'Parmesan',
            quantity: 50,
            unit: 'g',
            checked: true,
            category: 'Milchprodukte',
          ),
        ],
      );

      expect(text, contains('🛒 Einkaufsliste'));
      expect(text, contains('Cremige Gnocchi-Pfanne · 2 Personen'));
      expect(text, contains('Gemüse\n• 200 g Babyspinat'));
      expect(text, contains('Teigwaren\n• 500 g Gnocchi'));
      expect(text, isNot(contains('Parmesan')));
      expect(text, isNot(contains('Milchprodukte')));
    });

    test('merges duplicate open ingredients and excludes checked duplicates', () {
      final text = service.buildText(
        title: 'Einkaufsliste',
        items: const [
          ShoppingItem(
            id: '1',
            name: 'Tomaten',
            quantity: 200,
            unit: 'g',
            checked: false,
            category: 'Gemüse',
          ),
          ShoppingItem(
            id: '2',
            name: 'Tomaten',
            quantity: 300,
            unit: 'g',
            checked: false,
            category: 'Gemüse',
          ),
          ShoppingItem(
            id: '3',
            name: 'Tomaten',
            quantity: 100,
            unit: 'g',
            checked: true,
            category: 'Gemüse',
          ),
        ],
      );

      expect(text, contains('• 500 g Tomaten'));
      expect(text, isNot(contains('600 g')));
    });

    test('returns empty text when there are no open ingredients', () {
      final text = service.buildText(
        title: 'Einkaufsliste',
        items: const [
          ShoppingItem(
            id: '1',
            name: 'Zwiebel',
            quantity: 1,
            unit: 'Stück',
            checked: true,
          ),
        ],
      );

      expect(text, isEmpty);
    });
  });
}
