import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/recipe.dart';
import 'package:food_app_mvp/features/recipes/saved_recipes_page.dart';

void main() {
  const beefMain = Recipe(
    name: 'Rindergulasch',
    description: '',
    servings: 4,
    prepTimeMinutes: 15,
    cookTimeMinutes: 90,
    difficulty: 'Mittel',
    category: 'Hauptgericht',
    foodTags: ['Rind'],
    instructions: [],
    ingredients: [],
  );

  const vegetarianDessert = Recipe(
    name: 'Apfel-Tiramisu',
    description: '',
    servings: 6,
    prepTimeMinutes: 20,
    cookTimeMinutes: 0,
    difficulty: 'Einfach',
    category: 'Süßspeise',
    foodTags: ['Vegetarisch'],
    instructions: [],
    ingredients: [],
  );

  test('food tag filter works independently of recipe category', () {
    expect(recipeMatchesLibraryFilters(beefMain, foodTag: 'Rind'), isTrue);
    expect(recipeMatchesLibraryFilters(beefMain, category: 'Hauptgericht'), isTrue);
    expect(
      recipeMatchesLibraryFilters(beefMain, category: 'Süßspeise', foodTag: 'Rind'),
      isFalse,
    );
  });

  test('category and food tag filters combine with AND semantics', () {
    expect(
      recipeMatchesLibraryFilters(beefMain, category: 'Hauptgericht', foodTag: 'Rind'),
      isTrue,
    );
    expect(
      recipeMatchesLibraryFilters(vegetarianDessert, category: 'Süßspeise', foodTag: 'Vegetarisch'),
      isTrue,
    );
    expect(
      recipeMatchesLibraryFilters(vegetarianDessert, category: 'Hauptgericht', foodTag: 'Vegetarisch'),
      isFalse,
    );
  });

  test('recipes without explicit food tags are not guessed into a food filter', () {
    const unknown = Recipe(
      name: 'Unklar',
      description: '',
      servings: 2,
      prepTimeMinutes: 0,
      cookTimeMinutes: 0,
      difficulty: '',
      category: 'Hauptgericht',
      instructions: [],
      ingredients: [],
    );
    expect(recipeMatchesLibraryFilters(unknown, foodTag: 'Vegetarisch'), isFalse);
    expect(recipeMatchesLibraryFilters(unknown, category: 'Hauptgericht'), isTrue);
  });
}
