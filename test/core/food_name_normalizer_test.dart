import 'package:flutter_test/flutter_test.dart';
import 'package:fatzomat/core/food_name_normalizer.dart';

void main() {
  group('FoodNameNormalizer', () {
    test('matches singular and plural forms', () {
      expect(FoodNameNormalizer.matches('Tomaten', 'Tomate'), isTrue);
      expect(FoodNameNormalizer.matches('Kidneybohnen', 'Kidneybohne'), isTrue);
      expect(FoodNameNormalizer.equivalentOrContains('Champignons', 'Champignon'), isTrue);
      expect(FoodNameNormalizer.matches('Cashews', 'Cashew'), isTrue);
      expect(FoodNameNormalizer.matches('Kichererbsen', 'Kichererbse'), isTrue);
      expect(FoodNameNormalizer.matches('Zuckerschoten', 'Zuckerschote'), isTrue);
    });

    test('normalizes German umlauts, case and punctuation', () {
      expect(FoodNameNormalizer.matches('Süßkartoffeln', 'Suesskartoffel'), isTrue);
      expect(FoodNameNormalizer.matches('Kidney-Bohnen', 'Kidneybohne'), isTrue);
      expect(FoodNameNormalizer.matches('ERDNÜSSE', 'Erdnuss'), isTrue);
    });

    test('does not equate distinct compound foods in preference checks', () {
      expect(FoodNameNormalizer.equivalentOrContains('Paprikapulver', 'Paprika'), isFalse);
      expect(FoodNameNormalizer.equivalentOrContains('Paprika', 'Paprikapulver'), isFalse);
    });

    test('allows whole-word containment in longer ingredient names', () {
      expect(FoodNameNormalizer.equivalentOrContains('frische Champignons', 'Champignon'), isTrue);
    });

    test('empty query matches every food', () {
      expect(FoodNameNormalizer.matches('Tomaten', '  '), isTrue);
    });
  });
}
