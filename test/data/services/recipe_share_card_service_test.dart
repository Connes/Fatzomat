import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/recipe.dart';
import 'package:food_app_mvp/data/services/recipe_share_card_service.dart';

void main() {
  group('RecipeShareCardService', () {
    const service = RecipeShareCardService();

    test('shares only ingredients and preparation without recipe metadata', () {
      const recipe = Recipe(
        name: 'Fisch-Curry mit Reis',
        description: 'Cremiges Curry mit Seelachs.',
        servings: 2,
        prepTimeMinutes: 15,
        cookTimeMinutes: 15,
        difficulty: 'easy',
        ingredients: [
          RecipeIngredient(
            name: 'Basmatireis',
            quantity: 1,
            unit: 'Portion',
            section: 'Beilage',
          ),
          RecipeIngredient(
            name: 'Shiitakepilze',
            quantity: 75,
            unit: 'g',
            section: 'Curry',
          ),
          RecipeIngredient(
            name: 'Salz',
            quantity: 1,
            unit: '',
            isQualitative: true,
            section: 'Curry',
          ),
        ],
        instructions: ['Reis garen.', 'Curry zubereiten.'],
      );

      final text = service.buildRecipeText(recipe);

      expect(text, startsWith('*Zutaten*\n\n'));
      expect(text, contains('Beilage:\n• 1 Portion Basmatireis'));
      expect(text, contains('Curry:\n• 75 g Shiitakepilze\n• Salz'));
      expect(text, contains('*Zubereitung*\n\n1. Reis garen.\n2. Curry zubereiten.'));
      expect(text, isNot(contains('Fisch-Curry mit Reis')));
      expect(text, isNot(contains('Cremiges Curry')));
      expect(text, isNot(contains('Gesamtzeit')));
      expect(text, isNot(contains('Schwierigkeit')));
      expect(text, isNot(contains('Geteilt mit Fatzomat')));
    });

    test('omits empty ingredient or instruction sections', () {
      const recipe = Recipe(
        name: 'Einfaches Rezept',
        description: '',
        servings: 0,
        prepTimeMinutes: 0,
        cookTimeMinutes: 0,
        difficulty: 'Mittel',
        ingredients: [],
        instructions: ['Alles vermengen.'],
      );

      expect(
        service.buildRecipeText(recipe),
        '*Zubereitung*\n\n1. Alles vermengen.',
      );
    });

    test('returns empty text when ingredients and instructions are empty', () {
      const recipe = Recipe(
        name: 'Leeres Rezept',
        description: 'Beschreibung wird nicht geteilt.',
        servings: 4,
        prepTimeMinutes: 10,
        cookTimeMinutes: 20,
        difficulty: 'Mittel',
        ingredients: [],
        instructions: [],
      );

      expect(service.buildRecipeText(recipe), isEmpty);
    });
  });
}
