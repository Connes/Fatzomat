import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    expect(FoodItemImage.assetFor('Avocado'), 'assets/foods/avocado.svg');
    expect(FoodItemImage.assetFor('Brokkoli'), 'assets/foods/brokkoli.svg');
    expect(FoodItemImage.assetFor('Karotte'), 'assets/foods/karotte.svg');
    expect(FoodItemImage.assetFor('Karotten'), 'assets/foods/karotte.svg');
    expect(FoodItemImage.assetFor('Kartoffel'), 'assets/foods/kartoffel.svg');
    expect(FoodItemImage.assetFor('Kartoffeln'), 'assets/foods/kartoffel.svg');
    expect(FoodItemImage.assetFor('Tomate'), 'assets/foods/tomate.svg');
    expect(FoodItemImage.assetFor('Tomaten'), 'assets/foods/tomate.svg');
    expect(FoodItemImage.assetFor('Cherrytomaten'), 'assets/foods/tomate.svg');
    expect(FoodItemImage.assetFor('Zwiebel'), 'assets/foods/zwiebel.svg');
    expect(FoodItemImage.assetFor('Zwiebeln'), 'assets/foods/zwiebel.svg');
    expect(FoodItemImage.assetFor('Schalotte'), 'assets/foods/zwiebel.svg');
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

  testWidgets('dedicated vegetable SVG assets render without errors', (tester) async {
    const foods = [
      'Avocado',
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
      expect(tester.takeException(), isNull, reason: '$food SVG should render');
      expect(find.byType(SvgPicture), findsOneWidget, reason: '$food should use its SVG asset');
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
