import '../food_mode.dart';

class FoodDecisionService {
  static const cookChoices = ['Rind', 'Schwein', 'Huhn', 'Fisch', 'Vegetarisch'];
  static const orderChoices = ['Pizza', 'Burger', 'Asiatisch', 'Döner', 'Sushi', 'Indisch'];
  static const dineOutChoices = ['Italienisch', 'Steak', 'Asiatisch', 'Sushi', 'Burger', 'Mexikanisch', 'Vegetarisch'];

  static String surprise(FoodMode mode, {int? seed}) {
    final values = switch (mode) {
      FoodMode.cook => cookChoices,
      FoodMode.order => orderChoices,
      FoodMode.dineOut => dineOutChoices,
    };
    final index = (seed ?? DateTime.now().microsecondsSinceEpoch) % values.length;
    return values[index];
  }

  static FoodMode surpriseMode({int? seed}) {
    final values = FoodMode.values;
    final index = (seed ?? DateTime.now().microsecondsSinceEpoch) % values.length;
    return values[index];
  }
}
