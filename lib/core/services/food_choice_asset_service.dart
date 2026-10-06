import 'package:flutter/material.dart';

import '../food_mode.dart';

/// Central mapping from the semantic food choice to its dedicated UI asset.
class FoodChoiceAssetService {
  static const _cook = <String, String>{
    'Rind': 'assets/food_choices/cooking/rind.png',
    'Schwein': 'assets/food_choices/cooking/schwein.png',
    'Huhn': 'assets/food_choices/cooking/huhn.png',
    'Fisch': 'assets/food_choices/cooking/fisch.png',
    'Vegetarisch': 'assets/food_choices/cooking/vegetarisch.png',
  };

  static const _order = <String, String>{
    'Pizza': 'assets/food_choices/delivery/pizza.png',
    'Burger': 'assets/food_choices/delivery/burger.png',
    'Asiatisch': 'assets/food_choices/delivery/asiatisch.png',
    'Döner': 'assets/food_choices/delivery/doener.png',
    'Sushi': 'assets/food_choices/delivery/sushi.png',
    'Indisch': 'assets/food_choices/delivery/indisch.png',
    'Schnitzel': 'assets/food_choices/order/schnitzel.webp',
    'Pasta': 'assets/food_choices/order/pasta.webp',
  };

  static const _dineOut = <String, String>{
    'Italienisch': 'assets/food_choices/restaurant/italienisch.png',
    'Griechisch': 'assets/food_choices/restaurant/griechisch.png',
    'Türkisch': 'assets/food_choices/restaurant/tuerkisch.png',
    'Japanisch': 'assets/food_choices/restaurant/japanisch.png',
    'Chinesisch': 'assets/food_choices/restaurant/chinesisch.png',
    'Thailändisch': 'assets/food_choices/restaurant/thailaendisch.png',
    'Vietnamesisch': 'assets/food_choices/restaurant/vietnamesisch.png',
    'Koreanisch': 'assets/food_choices/restaurant/koreanisch.png',
    'Indonesisch': 'assets/food_choices/restaurant/indonesisch.png',
    'Malaysisch': 'assets/food_choices/restaurant/malaysisch.png',
    'Sushi': 'assets/food_choices/restaurant/sushi.png',
    'Burger': 'assets/food_choices/restaurant/burger.png',
    'Steak': 'assets/food_choices/restaurant/steak.png',
    'Mexikanisch': 'assets/food_choices/restaurant/mexikanisch.png',
    'Spanisch': 'assets/food_choices/restaurant/spanisch.png',
    'Libanesisch': 'assets/food_choices/restaurant/libanesisch.png',
    'Portugiesisch': 'assets/food_choices/restaurant/portugiesisch.png',
    'Vegetarisch': 'assets/food_choices/restaurant/vegetarisch.png',
    'Vegan': 'assets/food_choices/restaurant/vegan.png',
  };

  static const _surprise = 'assets/together/clean/icons/icon_surprise.png';

  static String? assetFor(FoodMode mode, String choice) {
    if (choice == 'Überrasch mich') return _surprise;
    final map = switch (mode) {
      FoodMode.cook => _cook,
      FoodMode.order => _order,
      FoodMode.dineOut => _dineOut,
    };
    return map[choice];
  }

  static IconData? iconFor(FoodMode mode, String choice) => null;

  static Map<String, String> choicesFor(FoodMode mode) => switch (mode) {
        FoodMode.cook => _cook,
        FoodMode.order => _order,
        FoodMode.dineOut => _dineOut,
      };
}
