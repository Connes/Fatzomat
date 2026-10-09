import 'package:flutter_test/flutter_test.dart';

import '../../lib/features/food_modes/delivery_services_page.dart';

void main() {
  group('deliveryServiceSearchUrl', () {
    test('uses Lieferando dedicated pizza page', () {
      expect(
        deliveryServiceSearchUrl('Lieferando', 'Pizza'),
        'https://www.lieferando.de/pizza-bestellen',
      );
    });

    test('normalizes whitespace and case for pizza', () {
      expect(
        deliveryServiceSearchUrl('Lieferando', '  PIZZA  '),
        'https://www.lieferando.de/pizza-bestellen',
      );
    });

    test('keeps other Lieferando categories as search queries', () {
      final uri = Uri.parse(deliveryServiceSearchUrl('Lieferando', 'Burger'));
      expect(uri.host, 'www.lieferando.de');
      expect(uri.path, '/suche');
      expect(uri.queryParameters['q'], 'Burger');
    });

    test('preserves a fallback for unknown services', () {
      expect(
        deliveryServiceSearchUrl(
          'Unknown',
          'Pizza',
          fallbackUrl: 'https://example.com/',
        ),
        'https://example.com/',
      );
    });
  });
}
