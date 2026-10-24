import 'package:flutter_test/flutter_test.dart';
import 'package:fatzomat/core/food_name_normalizer.dart';

void main() {
  group('FoodNameNormalizer', () {
    test('matches singular and plural forms', () {
      expect(FoodNameNormalizer.matches('Tomaten', 'Tomate'), isTrue);
      expect(FoodNameNormalizer.matches('Kidneybohnen', 'Kidneybohne'), isTrue);
      expect(FoodNameNormalizer.equivalentOrContains('Champignons', 'Champignon'), isTrue);
    });

    test('normalizes German umlauts and punctuation', () {
      expect(FoodNameNormalizer.matches('Süßkartoffeln', 'Suesskartoffel'), isTrue);
      expect(FoodNameNormalizer.matches('Kidney-Bohnen', 'Kidneybohne'), isTrue);
    });

    test('does not equate unrelated compound foods', () {
      expect(FoodNameNormalizer.equivalentOrContains('Paprikapulver', 'Paprika'), isFalse);
    });

    test('empty query matches every food', () {
      expect(FoodNameNormalizer.matches('Tomaten', '  '), isTrue);
    });
  });
}
