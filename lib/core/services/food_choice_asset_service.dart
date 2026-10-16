import 'package:flutter/material.dart';

import '../food_mode.dart';

/// Central mapping from the semantic food choice to its dedicated UI asset.
class FoodChoiceAssetService {
  static const _cook = <String, String>{
    'Rind': 'assets/food_choices/cooking/rind.webp',
    'Schwein': 'assets/food_choices/cooking/schwein.webp',
    'Huhn': 'assets/food_choices/cooking/huhn.webp',
    'Fisch': 'assets/food_choices/cooking/fisch.webp',
    'Vegetarisch': 'assets/food_choices/cooking/vegetarisch.webp',
  };

  static const _order = <String, String>{
    'Pizza': 'assets/food_choices/delivery/pizza.webp',
    'Burger': 'assets/food_choices/delivery/burger.webp',
    'Asiatisch': 'assets/food_choices/delivery/asiatisch.webp',
    'Döner': 'assets/food_choices/delivery/doener.webp',
    'Sushi': 'assets/food_choices/delivery/sushi.webp',
    'Indisch': 'assets/food_choices/delivery/indisch.webp',
    'Schnitzel': 'assets/food_choices/delivery/schnitzel.webp',
    'Pasta': 'assets/food_choices/delivery/pasta.webp',
  };

  static const _dineOut = <String, String>{
    'Italienisch': 'assets/food_choices/restaurant/italienisch.webp',
    'Griechisch': 'assets/food_choices/restaurant/griechisch.webp',
    'Türkisch': 'assets/food_choices/restaurant/tuerkisch.webp',
    'Japanisch': 'assets/food_choices/restaurant/japanisch.webp',
    'Chinesisch': 'assets/food_choices/restaurant/chinesisch.webp',
    'Thailändisch': 'assets/food_choices/restaurant/thailaendisch.webp',
    'Vietnamesisch': 'assets/food_choices/restaurant/vietnamesisch.webp',
    'Koreanisch': 'assets/food_choices/restaurant/koreanisch.webp',
    'Indonesisch': 'assets/food_choices/restaurant/indonesisch.webp',
    'Malaysisch': 'assets/food_choices/restaurant/malaysisch.webp',
    'Sushi': 'assets/food_choices/restaurant/sushi.webp',
    'Burger': 'assets/food_choices/restaurant/burger.webp',
    'Steak': 'assets/food_choices/restaurant/steak.webp',
    'Mexikanisch': 'assets/food_choices/restaurant/mexikanisch.webp',
    'Spanisch': 'assets/food_choices/restaurant/spanisch.webp',
    'Libanesisch': 'assets/food_choices/restaurant/libanesisch.webp',
    'Portugiesisch': 'assets/food_choices/restaurant/portugiesisch.webp',
    'Vegetarisch': 'assets/food_choices/restaurant/vegetarisch.webp',
    'Vegan': 'assets/food_choices/restaurant/vegan.webp',
    'Deutsch': 'assets/food_choices/restaurant/deutsch.webp',
    'Französisch': 'assets/food_choices/restaurant/franzoesisch.webp',
    'Indisch': 'assets/food_choices/restaurant/indisch.webp',
    'Amerikanisch': 'assets/food_choices/restaurant/amerikanisch.webp',
    'Afrikanisch': 'assets/food_choices/restaurant/afrikanisch.webp',
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
