import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/food.dart';
import 'package:food_app_mvp/data/models/recipe.dart';

import 'package:food_app_mvp/features/recipes/saved_recipes_page.dart';

void main() {
  test('V94 filtert gespeicherte Rezepte nach Hauptauswahl und Zutaten', () {
    final porkRice = {
      'id': '1',
      'name': 'Schwein mit Reis',
      'recipe_ingredients': [
        {'food_id': 'pork', 'name': 'Schwein'},
        {'food_id': 'rice', 'name': 'Reis'},
      ],
    };
    final porkPotato = {
      'id': '2',
      'name': 'Schwein mit Kartoffeln',
      'recipe_ingredients': [
        {'food_id': 'pork', 'name': 'Schwein'},
        {'food_id': 'potato', 'name': 'Kartoffel'},
      ],
    };

    expect(
      recipeMatchesSelection(porkRice, mainChoice: 'Schwein', selectedFoodIds: {'rice'}),
      isTrue,
    );
    expect(
      recipeMatchesSelection(porkPotato, mainChoice: 'Schwein', selectedFoodIds: {'rice'}),
      isFalse,
    );
    expect(
      recipeMatchesSelection(porkRice, mainChoice: 'Rind'),
      isFalse,
    );
  });

  test('V94 Vegetarisch schließt Fleisch und Fisch aus', () {
    final vegetarian = {
      'recipe_ingredients': [
        {'food_id': 'rice', 'name': 'Reis'},
        {'food_id': 'broccoli', 'name': 'Brokkoli'},
      ],
    };
    final meat = {
      'recipe_ingredients': [
        {'food_id': 'beef', 'name': 'Rind'},
        {'food_id': 'rice', 'name': 'Reis'},
      ],
    };

    expect(recipeMatchesSelection(vegetarian, mainChoice: 'Vegetarisch'), isTrue);
    expect(recipeMatchesSelection(meat, mainChoice: 'Vegetarisch'), isFalse);
  });

  test('V94 ohne Zutatenfilter bleibt der Hauptauswahlfilter aktiv', () {
    final recipe = {
      'recipe_ingredients': [
        {'food_id': 'chicken', 'name': 'Huhn'},
      ],
    };
    expect(recipeMatchesSelection(recipe, mainChoice: 'Huhn'), isTrue);
    expect(recipeMatchesSelection(recipe, mainChoice: 'Schwein'), isFalse);
  });

  test('saved recipe selection matches selected foods by name when food_id is absent', () {
    final recipe = Recipe(
      name: 'Rind mit Zucchini',
      description: '',
      servings: 2,
      prepTimeMinutes: 10,
      cookTimeMinutes: 20,
      difficulty: 'Einfach',
      instructions: const [],
      ingredients: const [
        RecipeIngredient(name: 'Rinderhack', quantity: 300, unit: 'g'),
        RecipeIngredient(name: 'Zucchini', quantity: 1, unit: 'Stück'),
      ],
    );
    expect(
      recipeModelMatchesSelection(
        recipe,
        mainChoice: 'Rind',
        selectedFoodIds: {'zucchini-id'},
        availableFoods: const [
          Food(
            id: 'zucchini-id',
            name: 'Zucchini',
            category: 'Gemüse',
            aliases: ['Courgette'],
          ),
        ],
      ),
      isTrue,
    );
  });

}
