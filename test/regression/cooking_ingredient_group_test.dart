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

  test('nur Gemüse und Beilagen verlassen Sonstiges', () {
    for (final item in [
      food('Hähnchenfleisch', 'Fleisch'),
      food('Lachs', 'Fisch'),
      food('Apfel', 'Obst'),
      food('Joghurt', 'Milchprodukte & Eier'),
      food('Olivenöl', 'Saucen & Grundzutaten'),
      food('Petersilie', 'Gewürze & Kräuter'),
      food('Haferflocken', 'Getreide & Beilagen'),
      food('Semmelbrösel', 'Getreide & Beilagen'),
      food('Lasagneplatten', 'Getreide & Beilagen'),
      food('Tortillas', 'Getreide & Beilagen'),
    ]) {
      expect(
        cookingIngredientGroup(item),
        CookingIngredientGroup.other,
        reason: '${item.name} muss in Sonstiges erscheinen',
      );
    }
  });

  test('Reisvarianten bleiben sichtbar unter Beilagen', () {
    for (final name in ['Reis', 'Basmatireis', 'Vollkornreis', 'Risottoreis']) {
      expect(
        cookingIngredientGroup(food(name, 'Getreide & Beilagen')),
        CookingIngredientGroup.side,
        reason: '$name soll bei Beilagen erscheinen',
      );
    }
  });
}
