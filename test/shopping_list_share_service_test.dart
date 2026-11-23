import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/shopping_item.dart';
import 'package:food_app_mvp/data/services/shopping_list_share_service.dart';

void main() {
  group('ShoppingListShareService', () {
    const service = ShoppingListShareService();

    test('formats recipe title, servings, bold heading and italic categories', () {
      final text = service.buildText(
        title: 'Meine Einkaufsliste',
        subtitle: 'Cremige Gnocchi-Pfanne',
        servings: 2,
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
            category: 'Weitere Zutaten',
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

      expect(
        text,
        '🛒 Meine Einkaufsliste\n\n'
        'Cremige Gnocchi-Pfanne\n'
        '2 Personen\n\n'
        '*Offene Zutaten*\n\n'
        '_Gemüse_\n'
        '• 200 g Babyspinat\n\n'
        '_Weitere Zutaten_\n'
        '• 500 g Gnocchi',
      );
      expect(text, isNot(contains('Parmesan')));
      expect(text, isNot(contains('Geteilt mit')));
    });

    test('does not add recipe metadata for a combined list', () {
      final text = service.buildText(
        title: 'Meine Einkaufsliste',
        items: const [
          ShoppingItem(
            id: '1',
            name: 'Tomaten',
            quantity: 200,
            unit: 'g',
            checked: false,
            category: 'Gemüse',
          ),
        ],
      );

      expect(text, contains('🛒 Meine Einkaufsliste\n\n*Offene Zutaten*'));
      expect(text, isNot(contains('Personen')));
    });

    test('merges duplicate open ingredients and excludes checked duplicates', () {
      final text = service.buildText(
        title: 'Meine Einkaufsliste',
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
        title: 'Meine Einkaufsliste',
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
