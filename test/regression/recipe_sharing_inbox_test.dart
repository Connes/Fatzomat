import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new recipes notify the connected person instead of creating a suggestion inbox item', () {
    final migration = File('supabase/migrations/20260928100000_shared_recipe_collection_v2.sql').readAsStringSync();
    final repo = File('lib/data/repositories/recipe_repository.dart').readAsStringSync();
    final detail = File('lib/features/recipes/recipe_detail_page.dart').readAsStringSync();
    final saved = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();
    final notifications = File('lib/features/settings/notifications_page.dart').readAsStringSync();
    final push = File('lib/core/push_notification_service.dart').readAsStringSync();
    final function = File('supabase/functions/push-notification/index.ts').readAsStringSync();

    expect(migration, contains("'recipe_created'"));
    expect(migration, contains("'Neues Rezept'"));
    expect(migration, contains('recipe_id'));
    expect(migration, contains('cm.user_id<>uid'));
    expect(migration, isNot(contains("'recipe_suggestion'")));
    expect(repo, contains('create_shared_recipe'));
    expect(detail, isNot(contains('suggestRecipe')));
    expect(saved, isNot(contains('RecipeSuggestion')));
    expect(saved, isNot(contains('receivedRecipeSuggestions')));
    expect(notifications, contains("item.type == 'recipe_created'"));
    expect(notifications, contains('RecipeDetailPage(recipeId: item.recipeId!)'));
    expect(push, contains("'recipe_id'"));
    expect(push, contains('RecipeDetailPage'));
    expect(function, contains("recipe_id: String(notification.recipe_id ?? '')"));
  });

  test('accepting a recipe is no longer part of the active recipe workflow', () {
    final saved = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();
    final detail = File('lib/features/recipes/recipe_detail_page.dart').readAsStringSync();
    expect(saved, isNot(contains('respondToIncomingRecipe')));
    expect(saved, isNot(contains('Annehmen')));
    expect(saved, isNot(contains('Ablehnen')));
    expect(detail, isNot(contains('Rezept teilen')));
  });
}
