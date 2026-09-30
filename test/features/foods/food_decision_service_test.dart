import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/core/services/food_decision_service.dart';
import 'package:food_app_mvp/core/food_mode.dart';

void main() {
  test('surprise mode is deterministic with a seed', () {
    expect(FoodDecisionService.surpriseMode(seed: 0), FoodMode.cook);
    expect(FoodDecisionService.surpriseMode(seed: 1), FoodMode.order);
    expect(FoodDecisionService.surpriseMode(seed: 2), FoodMode.dineOut);
  });

  test('surprise choice always belongs to the selected mode', () {
    expect(FoodDecisionService.surprise(FoodMode.cook, seed: 1), 'Schwein');
    expect(FoodDecisionService.surprise(FoodMode.order, seed: 2), 'Asiatisch');
    expect(FoodDecisionService.surprise(FoodMode.dineOut, seed: 3), 'Sushi');
  });
}
