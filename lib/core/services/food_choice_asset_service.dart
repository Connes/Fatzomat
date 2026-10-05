import 'package:flutter/material.dart';

import '../food_mode.dart';

/// Central mapping from the semantic food choice to its dedicated UI asset.
///
/// Keep this mapping in one place so FoodModePage does not accumulate
/// mode-specific asset paths and so tests can verify the complete coverage.
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
  };

  static const _dineOut = <String, String>{
    'Italienisch': 'assets/food_choices/restaurant/italienisch.png',
    'Griechisch': 'assets/food_choices/restaurant/griechisch.svg',
    'Türkisch': 'assets/food_choices/restaurant/tuerkisch.svg',
    'Japanisch': 'assets/food_choices/restaurant/japanisch.svg',
    'Chinesisch': 'assets/food_choices/restaurant/chinesisch.svg',
    'Thailändisch': 'assets/food_choices/restaurant/thailaendisch.svg',
    'Vietnamesisch': 'assets/food_choices/restaurant/vietnamesisch.svg',
    'Koreanisch': 'assets/food_choices/restaurant/koreanisch.svg',
    'Indonesisch': 'assets/food_choices/restaurant/indonesisch.svg',
    'Malaysisch': 'assets/food_choices/restaurant/malaysisch.svg',
    'Sushi': 'assets/food_choices/restaurant/sushi.png',
    'Burger': 'assets/food_choices/restaurant/burger.png',
    'Steak': 'assets/food_choices/restaurant/steak.png',
    'Mexikanisch': 'assets/food_choices/restaurant/mexikanisch.png',
    'Spanisch': 'assets/food_choices/restaurant/spanisch.svg',
    'Libanesisch': 'assets/food_choices/restaurant/libanesisch.svg',
    'Portugiesisch': 'assets/food_choices/restaurant/portugiesisch.svg',
    'Vegetarisch': 'assets/food_choices/restaurant/vegetarisch.png',
    'Vegan': 'assets/food_choices/restaurant/vegan.svg',
  };

  static const _surprise =
      'assets/together/clean/icons/icon_surprise.png';

  static String? assetFor(FoodMode mode, String choice) {
    if (choice == 'Überrasch mich') return _surprise;
    final map = switch (mode) {
      FoodMode.cook => _cook,
      FoodMode.order => _order,
      FoodMode.dineOut => _dineOut,
    };
    return map[choice];
  }

  static IconData? iconFor(FoodMode mode, String choice) {
    if (mode == FoodMode.dineOut) return _dineOutIcons[choice];
    return null;
  }

  static Map<String, String> choicesFor(FoodMode mode) => switch (mode) {
        FoodMode.cook => _cook,
        FoodMode.order => _order,
        FoodMode.dineOut => _dineOut,
      };
}
