import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/features/foods/food_item_image.dart';

void main() {
  test('known foods resolve to dedicated WebP assets', () {
    expect(FoodItemImage.assetFor('Apfel'), 'assets/foods/apfel.webp');
    expect(FoodItemImage.assetFor(' Forelle '), 'assets/foods/forelle.webp');
    expect(FoodItemImage.assetFor('Lachs'), 'assets/foods/lachs.webp');
    expect(FoodItemImage.assetFor('Kabeljau'), 'assets/foods/kabeljau.webp');
    expect(FoodItemImage.assetFor('Makrele'), 'assets/foods/makrele.webp');
    expect(FoodItemImage.assetFor('Pangasius'), 'assets/foods/pangasius.webp');
    expect(FoodItemImage.assetFor('Räucherlachs'), 'assets/foods/raeucherlachs.webp');
    expect(FoodItemImage.assetFor('Rotbarsch'), 'assets/foods/rotbarsch.webp');
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
    expect(FoodItemImage.assetFor('Avocado'), 'assets/foods/avocado.webp');
    expect(FoodItemImage.assetFor('Aubergine'), 'assets/foods/aubergine.webp');
    expect(FoodItemImage.assetFor('Champignons'), 'assets/foods/champignons.webp');
    expect(FoodItemImage.assetFor('Austernpilze'), 'assets/foods/champignons.webp');
    expect(FoodItemImage.assetFor('Shiitake-Pilze'), 'assets/foods/champignons.webp');
    expect(FoodItemImage.assetFor('Erbsen'), 'assets/foods/erbsen.webp');
    expect(FoodItemImage.assetFor('Mais'), 'assets/foods/mais.webp');
    expect(FoodItemImage.assetFor('Kürbis'), 'assets/foods/kuerbis.webp');
    expect(FoodItemImage.assetFor('Kuerbis'), 'assets/foods/kuerbis.webp');
    expect(FoodItemImage.assetFor('Frühlingszwiebel'), 'assets/foods/fruehlingszwiebel.webp');
    expect(FoodItemImage.assetFor('Fruehlingszwiebel'), 'assets/foods/fruehlingszwiebel.webp');
    expect(FoodItemImage.assetFor('Gurke'), 'assets/foods/gurke.webp');
    expect(FoodItemImage.assetFor('Paprika'), 'assets/foods/paprika.webp');
    expect(FoodItemImage.assetFor('Zucchini'), 'assets/foods/zucchini.webp');
    expect(FoodItemImage.assetFor('Blumenkohl'), 'assets/foods/blumenkohl.webp');
    expect(FoodItemImage.assetFor('Spinat'), 'assets/foods/spinat.webp');
    expect(FoodItemImage.assetFor('Knoblauch'), 'assets/foods/knoblauch.webp');
    expect(FoodItemImage.assetFor('Brokkoli'), 'assets/foods/brokkoli.webp');
    expect(FoodItemImage.assetFor('Karotte'), 'assets/foods/karotte.webp');
    expect(FoodItemImage.assetFor('Karotten'), 'assets/foods/karotte.webp');
    expect(FoodItemImage.assetFor('Kartoffel'), 'assets/foods/kartoffel.webp');
    expect(FoodItemImage.assetFor('Kartoffeln'), 'assets/foods/kartoffel.webp');
    expect(FoodItemImage.assetFor('Tomate'), 'assets/foods/tomate.webp');
    expect(FoodItemImage.assetFor('Tomaten'), 'assets/foods/tomate.webp');
    expect(FoodItemImage.assetFor('Cherrytomaten'), 'assets/foods/tomate.webp');
    expect(FoodItemImage.assetFor('Zwiebel'), 'assets/foods/zwiebel.webp');
    expect(FoodItemImage.assetFor('Zwiebeln'), 'assets/foods/zwiebel.webp');
    expect(FoodItemImage.assetFor('Schalotte'), 'assets/foods/zwiebel.webp');
    expect(FoodItemImage.assetFor('Unbekanntes Lebensmittel'), isNull);
  });

  testWidgets('dedicated food assets decode when rendered', (tester) async {
    for (final food in ['Apfel', 'Forelle', 'Lachs', 'Kabeljau', 'Makrele', 'Pangasius', 'Räucherlachs', 'Rotbarsch', 'Dorade', 'Heilbutt', 'Hering', 'Banane', 'Zitrone', 'Erdbeeren', 'Heidelbeeren', 'Himbeeren', 'Birne', 'Orange', 'Mango', 'Ananas', 'Trauben', 'Kiwi', 'Limette', 'Mandarine', 'Pfirsich', 'Wassermelone']) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: FoodItemImage(foodName: food))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$food asset should decode');
      expect(find.byType(Image), findsOneWidget, reason: '$food should use its WebP asset');
    }
  });

  testWidgets('dedicated vegetable WebP assets render without errors', (tester) async {
    const foods = [
      'Avocado',
      'Aubergine',
      'Champignons',
      'Austernpilze',
      'Shiitake-Pilze',
      'Erbsen',
      'Mais',
      'Kürbis',
      'Frühlingszwiebel',
      'Fruehlingszwiebel',
      'Gurke',
      'Paprika',
      'Zucchini',
      'Blumenkohl',
      'Spinat',
      'Knoblauch',
      'Brokkoli',
      'Karotte',
      'Karotten',
      'Kartoffel',
      'Kartoffeln',
      'Tomate',
      'Tomaten',
      'Cherrytomaten',
      'Zwiebel',
      'Zwiebeln',
      'Schalotte',
    ];
    for (final food in foods) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: FoodItemImage(foodName: food)),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$food WebP should render');
      expect(find.byType(Image), findsOneWidget, reason: '$food should use its WebP asset');
    }
  });

  test('dedicated produce WebP assets are exactly 128x128', () async {
    const assets = [
      'aubergine.webp',
      'avocado.webp',
      'blumenkohl.webp',
      'brokkoli.webp',
      'champignons.webp',
      'erbsen.webp',
      'fruehlingszwiebel.webp',
      'gurke.webp',
      'karotte.webp',
      'kartoffel.webp',
      'knoblauch.webp',
      'kuerbis.webp',
      'mais.webp',
      'paprika.webp',
      'spinat.webp',
      'tomate.webp',
      'zucchini.webp',
      'zwiebel.webp',
    ];

    for (final asset in assets) {
      final data = await rootBundle.load('assets/foods/$asset');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 128, reason: '$asset width');
      expect(frame.image.height, 128, reason: '$asset height');
      frame.image.dispose();
      codec.dispose();
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
