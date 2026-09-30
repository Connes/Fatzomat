import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/recipe.dart';
import 'package:food_app_mvp/data/services/backup_service.dart';

void main() {
  test('builds a versioned personal backup without credentials', () {
    const recipe = Recipe(
      name: 'Nudeln',
      description: 'Schnell',
      servings: 2,
      prepTimeMinutes: 5,
      cookTimeMinutes: 10,
      difficulty: 'Einfach',
      instructions: ['Kochen.'],
      ingredients: [RecipeIngredient(name: 'Nudeln', quantity: 200, unit: 'g')],
    );

    final backup = BackupService.buildPayload(
      profile: null,
      preferences: const {'rice': 'like'},
      recipes: const [recipe],
    );

    expect(backup['format'], 'schmackofatz_backup');
    expect(backup['profile'], isNull);
    expect(backup['version'], 1);
    expect(backup.containsKey('access_token'), isFalse);
    expect(backup.containsKey('refresh_token'), isFalse);
    expect((backup['recipes'] as List), hasLength(1));
    expect(((backup['recipes'] as List).first as Map)['format'], 'together_recipe');
  });
}
