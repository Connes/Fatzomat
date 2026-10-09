import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/features/foods/food_item_image.dart';

void main() {
  test('catalog foods have stable emoji illustrations', () {
    const foods = <String, String>{
      'Rinderfilet': '🐄', 'Hähnchenflügel': '🍗', 'Dorade': '🐠',
      'Räucherlachs': '🍣', 'Rinderhackfleisch': '🐄', 'Speck': '🐷', 'Tintenfisch': '🦑', 'Fenchel': '🌿',
      'Rote Bete': '🟣', 'Schweinebraten': '🐷', 'Entenbrust': '🦆', 'Zuckerschoten': '🫛', 'Dill': '🌿',
      'Garam Masala': '🌿', 'Kardamom': '🌿', 'Miesmuscheln': '🦪',
      'Kokosmilch': '🥥', 'Apfel': '🍎', 'Ei': '🥚',
    };
    for (final entry in foods.entries) {
      expect(FoodItemImage.emojiFor(entry.key), entry.value, reason: entry.key);
    }
  });

  test('unknown foods use a category-specific emoji fallback', () {
    expect(FoodItemImage.emojiFor('Halloumi', category: 'Milchprodukte & Eier'), '🥚');
    expect(FoodItemImage.emojiFor('Eigenes Gemüse', category: 'Gemüse'), '🥬');
    expect(FoodItemImage.emojiFor('Unbekanntes Lebensmittel'), '🍽️');
  });
}
