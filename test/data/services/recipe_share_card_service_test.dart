import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/recipe.dart';
import 'package:food_app_mvp/data/services/recipe_share_card_service.dart';

void main() {
  group('RecipeShareCardService', () {
    const service = RecipeShareCardService();

    test('builds a readable recipe message with metadata, sections and steps', () {
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

      expect(text, contains('Fisch-Curry mit Reis'));
      expect(text, contains('Gesamtzeit: 30 Min. (15 + 15 Min.)'));
      expect(text, contains('Schwierigkeit: Einfach'));
      expect(text, contains('Beilage:\n• 1 Portion Basmatireis'));
      expect(text, contains('Curry:\n• 75 g Shiitakepilze\n• Salz'));
      expect(text, contains('ZUBEREITUNG\n1. Reis garen.\n2. Curry zubereiten.'));
    });

    test('keeps recipes shareable when optional content is empty', () {
      const recipe = Recipe(
        name: 'Einfaches Rezept',
        description: '',
        servings: 0,
        prepTimeMinutes: 0,
        cookTimeMinutes: 0,
        difficulty: 'Mittel',
        ingredients: [],
        instructions: [],
      );

      final text = service.buildRecipeText(recipe);

      expect(text, startsWith('Einfaches Rezept'));
      expect(text, contains('Schwierigkeit: Mittel'));
      expect(text, isNot(contains('ZUTATEN')));
      expect(text, isNot(contains('ZUBEREITUNG')));
    });
  });
}
