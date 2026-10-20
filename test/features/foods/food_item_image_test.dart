import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/features/foods/food_item_image.dart';

void main() {
  test('known foods resolve to dedicated WebP assets', () {
    expect(FoodItemImage.assetFor('Apfel'), 'assets/foods/apfel.webp');
    expect(FoodItemImage.assetFor(' Forelle '), 'assets/foods/forelle.webp');
    expect(FoodItemImage.assetFor('Lachs'), 'assets/foods/lachs.webp');
    expect(FoodItemImage.assetFor('Dorade'), 'assets/foods/dorade.webp');
    expect(FoodItemImage.assetFor('Heilbutt'), 'assets/foods/heilbutt.webp');
    expect(FoodItemImage.assetFor('Hering'), 'assets/foods/hering.webp');
    expect(FoodItemImage.assetFor('Banane'), 'assets/foods/banane.webp');
    expect(FoodItemImage.assetFor('Zitrone'), 'assets/foods/zitrone.webp');
    expect(FoodItemImage.assetFor('Erdbeeren'), 'assets/foods/erdbeeren.webp');
    expect(FoodItemImage.assetFor('Heidelbeeren'), 'assets/foods/heidelbeeren.webp');
    expect(FoodItemImage.assetFor('Himbeeren'), 'assets/foods/himbeeren.webp');
    expect(FoodItemImage.assetFor('Birne'), 'assets/foods/birne.webp');
    expect(FoodItemImage.assetFor('Orange'), 'assets/foods/orange.webp');
    expect(FoodItemImage.assetFor('Mango'), 'assets/foods/mango.webp');
    expect(FoodItemImage.assetFor('Ananas'), 'assets/foods/ananas.webp');
    expect(FoodItemImage.assetFor('Trauben'), 'assets/foods/trauben.webp');
    expect(FoodItemImage.assetFor('Kiwi'), 'assets/foods/kiwi.webp');
    expect(FoodItemImage.assetFor('Limette'), 'assets/foods/limette.webp');
    expect(FoodItemImage.assetFor('Mandarine'), 'assets/foods/mandarine.webp');
    expect(FoodItemImage.assetFor('Pfirsich'), 'assets/foods/pfirsich.webp');
    expect(FoodItemImage.assetFor('Wassermelone'), 'assets/foods/wassermelone.webp');
    expect(FoodItemImage.assetFor('Unbekanntes Lebensmittel'), isNull);
  });

  testWidgets('dedicated food assets decode when rendered', (tester) async {
    for (final food in ['Apfel', 'Forelle', 'Lachs', 'Dorade', 'Heilbutt', 'Hering', 'Banane', 'Zitrone', 'Erdbeeren', 'Heidelbeeren', 'Himbeeren', 'Birne', 'Orange', 'Mango', 'Ananas', 'Trauben', 'Kiwi', 'Limette', 'Mandarine', 'Pfirsich', 'Wassermelone']) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: FoodItemImage(foodName: food))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$food asset should decode');
      expect(find.byType(Image), findsOneWidget, reason: '$food should use its WebP asset');
    }
  });

  test('catalog foods have stable emoji illustrations', () {
    const foods = <String, String>{
      'Rinderfilet': '🐄', 'Hähnchenflügel': '🐔', 'Dorade': '🐟',
      'Räucherlachs': '🐟', 'Tintenfisch': '🦑', 'Fenchel': '🥬',
      'Rote Bete': '🫜', 'Radieschen': '🫜', 'Rettich': '🫜', 'Steckrübe': '🫜', 'Zuckerschoten': '🫛', 'Dill': '🌿',
      'Garam Masala': '🌿', 'Kardamom': '🌿', 'Miesmuscheln': '🦪',
      'Kokosmilch': '🥥', 'Backpulver': '🥄', 'Marmelade': '🍯', 'Vanillezucker': '🥄', 'Zucker': '🥄', 'Apfel': '🍎', 'Ei': '🥚',
      'Wassermelone': '🍉', 'Kiwi': '🥝', 'Olive': '🫒', 'Knoblauch': '🧄', 'Limette': '🍋‍🟩',
      'Schweinebraten': '🐖', 'Entenbrust': '🦆', 'Lammkotelett': '🐑', 'Kassler': '🐖',
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
