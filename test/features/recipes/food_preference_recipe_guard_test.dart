import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/food.dart';
import 'package:food_app_mvp/data/models/recipe.dart';
import 'package:food_app_mvp/features/recipes/food_preference_recipe_guard.dart';
import 'package:food_app_mvp/features/recipes/together_chatgpt_prompt.dart';

void main() {
  test('recipe prompt includes liked and disliked foods with clear rules', () {
    final prompt = TogetherChatGptPrompt.build(
      mainChoice: 'Huhn',
      selectedFoods: const [],
      likedFoods: const [
        Food(id: 'tomato', name: 'Tomaten', category: 'Gemüse'),
      ],
      dislikedFoods: const [
        Food(
          id: 'soy',
          name: 'Sojasauce',
          category: 'Saucen',
          aliases: ['Soja-Soße'],
        ),
      ],
    );

    expect(prompt, contains('Tomaten'));
    expect(prompt, contains('Sojasauce'));
    expect(prompt, contains('Soja-Soße'));
    expect(prompt, contains('streng ausschließen'));
    expect(prompt, contains('Bevorzuge Lebensmittel aus der Liste'));
  });

  test('guard detects disliked food by name and alias', () {
    final recipe = Recipe(
      name: 'Nudeln',
      description: '',
      servings: 2,
      prepTimeMinutes: 10,
      cookTimeMinutes: 15,
      difficulty: 'Einfach',
      instructions: const ['Kochen'],
      ingredients: const [
        RecipeIngredient(name: 'Sojasauce', quantity: 1, unit: 'EL'),
        RecipeIngredient(name: 'Tomaten', quantity: 2, unit: ''),
      ],
    );
    final foods = const [
      Food(
        id: 'soy',
        name: 'Soja-Soße',
        category: 'Saucen',
        aliases: ['Sojasauce'],
      ),
      Food(id: 'tomato', name: 'Tomaten', category: 'Gemüse'),
    ];

    expect(
      FoodPreferenceRecipeGuard.findDislikedIngredients(
        recipe: recipe,
        foods: foods,
        preferences: const {'soy': 'dislike', 'tomato': 'like'},
      ),
      ['Sojasauce'],
    );
  });

  test('guard allows recipes without disliked ingredients', () {
    final recipe = Recipe(
      name: 'Salat',
      description: '',
      servings: 2,
      prepTimeMinutes: 10,
      cookTimeMinutes: 0,
      difficulty: 'Einfach',
      instructions: const ['Mischen'],
      ingredients: const [
        RecipeIngredient(name: 'Tomaten', quantity: 2, unit: ''),
      ],
    );

    expect(
      FoodPreferenceRecipeGuard.findDislikedIngredients(
        recipe: recipe,
        foods: const [
          Food(id: 'soy', name: 'Sojasauce', category: 'Saucen'),
        ],
        preferences: const {'soy': 'dislike'},
      ),
      isEmpty,
    );
  });
}
