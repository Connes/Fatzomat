import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/food.dart';
import 'package:food_app_mvp/domain/foods/food_policy.dart';

void main() {
  test('uses structured taxonomy instead of display-name guessing', () {
    const vegan = Food(
      id: 'custom_1',
      name: 'Fischers Liebling',
      category: 'Sonstiges',
      dietaryType: 'vegan',
      proteinType: 'plant',
      allergens: ['soy'],
    );

    expect(FoodPolicy.isVegan(vegan), isTrue);
    expect(FoodPolicy.isVegetarian(vegan), isTrue);
    expect(FoodPolicy.isMeat(vegan), isFalse);
    expect(FoodPolicy.isFish(vegan), isFalse);
    expect(FoodPolicy.containsAllergen(vegan, 'SOY'), isTrue);
  });

  test('meat and fish classification comes only from protein_type', () {
    const meat = Food(
      id: 'm1',
      name: 'Rindfleisch',
      category: 'Sonstiges',
      dietaryType: 'omnivore',
      proteinType: 'meat',
    );
    const fish = Food(
      id: 'f1',
      name: 'Forelle',
      category: 'Sonstiges',
      dietaryType: 'omnivore',
      proteinType: 'fish',
    );

    expect(FoodPolicy.isMeat(meat), isTrue);
    expect(FoodPolicy.isFish(meat), isFalse);
    expect(FoodPolicy.isFish(fish), isTrue);
    expect(FoodPolicy.isMeat(fish), isFalse);
  });
}
