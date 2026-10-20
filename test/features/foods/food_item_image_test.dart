import 'dart:convert';
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
    expect(FoodItemImage.assetFor('Pastinake'), 'assets/foods/pastinake.webp');
    expect(FoodItemImage.assetFor('Pak Choi'), 'assets/foods/pak_choi.webp');
    expect(FoodItemImage.assetFor('Chinakohl'), 'assets/foods/chinakohl.webp');
    expect(FoodItemImage.assetFor('Chicorée'), 'assets/foods/chicoree.webp');
    expect(FoodItemImage.assetFor('Chicoree'), 'assets/foods/chicoree.webp');
    expect(FoodItemImage.assetFor('Endivie'), 'assets/foods/endivie.webp');
    expect(FoodItemImage.assetFor('Lauch'), 'assets/foods/lauch.webp');
    expect(FoodItemImage.assetFor('Mangold'), 'assets/foods/mangold.webp');
    expect(FoodItemImage.assetFor('Weißkohl'), 'assets/foods/weisskohl.webp');
    expect(FoodItemImage.assetFor('Weisskohl'), 'assets/foods/weisskohl.webp');
    expect(FoodItemImage.assetFor('Artischocke'), 'assets/foods/artischocke.webp');
    expect(FoodItemImage.assetFor('Kohlrabi'), 'assets/foods/kohlrabi.webp');
    expect(FoodItemImage.assetFor('Rosenkohl'), 'assets/foods/rosenkohl.webp');
    expect(FoodItemImage.assetFor('Fenchel'), 'assets/foods/fenchel.webp');
    expect(FoodItemImage.assetFor('Radieschen'), 'assets/foods/radieschen.webp');
    expect(FoodItemImage.assetFor('Rote Bete'), 'assets/foods/rote_bete.webp');
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
      'Fenchel',
      'Pak Choi',
      'Chinakohl',
      'Chicorée',
      'Chicoree',
      'Endivie',
      'Lauch',
      'Mangold',
      'Weißkohl',
      'Weisskohl',
      'Artischocke',
      'Kohlrabi',
      'Rosenkohl',
      'Pastinake',
      'Radieschen',
      'Rote Bete',
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

  test('every food WebP asset is exactly 128x128', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest
        .listAssets()
        .where((path) => path.startsWith('assets/foods/') && path.endsWith('.webp'))
        .toList()
      ..sort();

    expect(assets, isNotEmpty);
    for (final asset in assets) {
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF', reason: '$asset RIFF header');
      expect(ascii.decode(bytes.sublist(8, 12)), 'WEBP', reason: '$asset WebP header');
      final chunkType = ascii.decode(bytes.sublist(12, 16));
      late final int width;
      late final int height;
      if (chunkType == 'VP8X') {
        // Extended WebP stores 24-bit canvas dimensions minus one at bytes 24-29.
        width = 1 + bytes[24] + (bytes[25] << 8) + (bytes[26] << 16);
        height = 1 + bytes[27] + (bytes[28] << 8) + (bytes[29] << 16);
      } else if (chunkType == 'VP8 ') {
        // Lossy WebP stores 14-bit dimensions in the frame header.
        width = bytes[26] | ((bytes[27] & 0x3f) << 8);
        height = bytes[28] | ((bytes[29] & 0x3f) << 8);
      } else if (chunkType == 'VP8L') {
        // Lossless WebP packs width and height minus one into four bytes.
        expect(bytes[20], 0x2f, reason: '$asset VP8L signature');
        width = 1 + bytes[21] + ((bytes[22] & 0x3f) << 8);
        height = 1 + ((bytes[22] >> 6) & 0x03) + (bytes[23] << 2) +
            ((bytes[24] & 0x0f) << 10);
      } else {
        fail('$asset uses unsupported WebP chunk type: $chunkType');
      }
      expect(width, 128, reason: '$asset width');
      expect(height, 128, reason: '$asset height');
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

  test('dedicated food asset mappings never reference SVG files', () {
    const foods = ['Artischocke', 'Chicorée', 'Chicoree', 'Endivie', 'Lauch', 'Mangold', 'Kohlrabi', 'Rosenkohl', 'Pak Choi', 'Chinakohl', 'Weißkohl'];
    for (final food in foods) {
      final asset = FoodItemImage.assetFor(food);
      expect(asset, isNotNull, reason: '$food should have a dedicated asset');
      expect(asset, endsWith('.webp'), reason: '$food must use WebP, never SVG');
    }
  });

  test('unknown foods use a category-specific emoji fallback', () {
    expect(FoodItemImage.emojiFor('Halloumi', category: 'Milchprodukte & Eier'), '🥚');
    expect(FoodItemImage.emojiFor('Eigenes Gemüse', category: 'Gemüse'), '🥬');
    expect(FoodItemImage.emojiFor('Unbekanntes Lebensmittel'), '🍽️');
  });
}
