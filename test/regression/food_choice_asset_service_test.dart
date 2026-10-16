import 'package:flutter_test/flutter_test.dart';

import 'package:food_app_mvp/core/food_mode.dart';
import 'package:food_app_mvp/core/services/food_choice_asset_service.dart';

void main() {
  test('restaurant mode has dedicated artwork for every category', () {
    const choices = <String>[
      'Italienisch',
      'Griechisch',
      'Türkisch',
      'Japanisch',
      'Chinesisch',
      'Thailändisch',
      'Vietnamesisch',
      'Koreanisch',
      'Indonesisch',
      'Malaysisch',
      'Sushi',
      'Burger',
      'Steak',
      'Mexikanisch',
      'Spanisch',
      'Libanesisch',
      'Portugiesisch',
      'Vegetarisch',
      'Vegan',
      'Deutsch',
      'Französisch',
      'Indisch',
      'Amerikanisch',
      'Afrikanisch',
      'Überrasch mich',
    ];

    for (final choice in choices) {
      expect(
        FoodChoiceAssetService.assetFor(FoodMode.dineOut, choice),
        isNotNull,
        reason: 'Fehlendes Restaurant-Asset für $choice',
      );
    }
  });

  test('order mode maps every food choice to the new delivery artwork', () {
    const expected = <String, String>{
      'Pizza': 'assets/food_choices/delivery/pizza.webp',
      'Burger': 'assets/food_choices/delivery/burger.webp',
      'Asiatisch': 'assets/food_choices/delivery/asiatisch.webp',
      'Döner': 'assets/food_choices/delivery/doener.webp',
      'Sushi': 'assets/food_choices/delivery/sushi.webp',
      'Indisch': 'assets/food_choices/delivery/indisch.webp',
      'Schnitzel': 'assets/food_choices/delivery/schnitzel.webp',
      'Pasta': 'assets/food_choices/delivery/pasta.webp',
    };

    for (final entry in expected.entries) {
      expect(
        FoodChoiceAssetService.assetFor(FoodMode.order, entry.key),
        entry.value,
        reason: 'Falsches Delivery-Asset',
      );
    }
  });

  test('restaurant categories use dedicated WebP artwork instead of icon fallbacks', () {
    const categories = <String>[
      'Italienisch',
      'Griechisch',
      'Türkisch',
      'Japanisch',
      'Chinesisch',
      'Thailändisch',
      'Vietnamesisch',
      'Koreanisch',
      'Indonesisch',
      'Malaysisch',
      'Sushi',
      'Burger',
      'Steak',
      'Mexikanisch',
      'Spanisch',
      'Libanesisch',
      'Portugiesisch',
      'Vegetarisch',
      'Vegan',
      'Deutsch',
      'Französisch',
      'Indisch',
      'Amerikanisch',
      'Afrikanisch',
    ];

    for (final choice in categories) {
      expect(
        FoodChoiceAssetService.iconFor(FoodMode.dineOut, choice),
        isNull,
        reason: '$choice darf keinen generischen Icon-Fallback mehr verwenden',
      );
      expect(
        FoodChoiceAssetService.assetFor(FoodMode.dineOut, choice),
        endsWith('.webp'),
        reason: '$choice soll ein eigenes Restaurant-WebP-Asset verwenden',
      );
    }
  });
}
