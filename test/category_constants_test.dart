import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/core/constants.dart';

void main() {
  test('category vocabulary is unique and contains the recipe-hidden groups', () {
    expect(foodCategories.toSet().length, foodCategories.length);
    expect(foodCategories, contains('Getreide & Beilagen'));
    expect(foodCategories, contains('Saucen & Grundzutaten'));
    expect(foodCategories, contains('Backen & Süßes'));
    expect(hiddenRecipeCategories, contains('Gewürze'));
    expect(hiddenRecipeCategories, contains('Saucen & Grundzutaten'));
  });
}
