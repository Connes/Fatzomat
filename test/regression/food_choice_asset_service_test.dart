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
      'Pizza': 'assets/food_choices/delivery/pizza.png',
      'Burger': 'assets/food_choices/delivery/burger.png',
      'Asiatisch': 'assets/food_choices/delivery/asiatisch.png',
      'Döner': 'assets/food_choices/delivery/doener.png',
      'Sushi': 'assets/food_choices/delivery/sushi.png',
      'Indisch': 'assets/food_choices/delivery/indisch.png',
      'Schnitzel': 'assets/food_choices/delivery/schnitzel.png',
      'Pasta': 'assets/food_choices/delivery/pasta.png',
    };

    for (final entry in expected.entries) {
      expect(
        FoodChoiceAssetService.assetFor(FoodMode.order, entry.key),
        entry.value,
        reason: 'Falsches Delivery-Asset',
      );
    }
  });

  test('new restaurant categories use dedicated artwork instead of icon fallbacks', () {
    const newCategories = <String>[
      'Griechisch',
      'Türkisch',
      'Japanisch',
      'Chinesisch',
      'Thailändisch',
      'Vietnamesisch',
      'Koreanisch',
      'Indonesisch',
      'Malaysisch',
      'Spanisch',
      'Libanesisch',
      'Portugiesisch',
      'Vegan',
    ];

    for (final choice in newCategories) {
      expect(
        FoodChoiceAssetService.iconFor(FoodMode.dineOut, choice),
        isNull,
        reason: '$choice darf keinen generischen Icon-Fallback mehr verwenden',
      );
      expect(
        FoodChoiceAssetService.assetFor(FoodMode.dineOut, choice),
        endsWith('.png'),
        reason: '$choice soll ein eigenes Restaurant-Food-Asset verwenden',
      );
    }
  });
}
