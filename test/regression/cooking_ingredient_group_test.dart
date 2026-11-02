import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/food.dart';
import 'package:food_app_mvp/features/recipes/cooking_ingredient_group.dart';

Food food(String name, String category) => Food(
      id: name,
      name: name,
      category: category,
    );

void main() {
  test('Salat und Blattsalat werden nicht als Gemüse einsortiert', () {
    for (final name in ['Salat', 'Feldsalat', 'Rucola', 'Endivie', 'Chicorée']) {
      expect(
        cookingIngredientGroup(food(name, 'Gemüse')),
        CookingIngredientGroup.other,
        reason: '$name darf nicht in Gemüse erscheinen',
      );
    }
  });

  test('Bohnen und Kichererbsen erscheinen bei Gemüse', () {
    for (final name in [
      'Schwarze Bohnen',
      'Weiße Bohnen',
      'Kidney-Bohnen',
      'Kichererbsen',
    ]) {
      expect(
        cookingIngredientGroup(food(name, 'Hülsenfrüchte')),
        CookingIngredientGroup.vegetables,
        reason: '$name soll bei Gemüse erscheinen',
      );
    }
  });

  test('Linsen bleiben Beilage', () {
    expect(
      cookingIngredientGroup(food('Linsen', 'Hülsenfrüchte')),
      CookingIngredientGroup.side,
    );
  });

  test('gewünschte Zutaten wechseln zu Sonstiges', () {
    for (final name in [
      'Semmelbrösel',
      'Haferflocken',
      'Lasagneplatten',
      'Tortillas',
    ]) {
      expect(
        cookingIngredientGroup(food(name, 'Getreide & Beilagen')),
        CookingIngredientGroup.other,
        reason: '$name soll bei Sonstiges erscheinen',
      );
    }
  });

  test('Reis erscheint nur als allgemeiner Eintrag', () {
    expect(cookingIngredientGroup(food('Reis', 'Getreide & Beilagen')),
        CookingIngredientGroup.side);
    for (final name in ['Basmatireis', 'Vollkornreis', 'Risottoreis']) {
      expect(
        cookingIngredientGroup(food(name, 'Getreide & Beilagen')),
        CookingIngredientGroup.hidden,
        reason: '$name soll nicht angezeigt werden',
      );
    }
  });
}
