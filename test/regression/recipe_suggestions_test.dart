import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared recipe collection replaces the active recipe suggestion workflow', () {
    final migration = File('supabase/migrations/20260928100000_shared_recipe_collection_v2.sql').readAsStringSync();
    final addRecipe = File('lib/features/recipes/add_recipe_page.dart').readAsStringSync();
    final saved = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();
    final detail = File('lib/features/recipes/recipe_detail_page.dart').readAsStringSync();
    final notifications = File('lib/features/settings/notifications_page.dart').readAsStringSync();

    expect(migration, contains('create or replace function public.create_shared_recipe'));
    expect(migration, contains('create or replace function public.update_shared_recipe'));
    expect(migration, contains('create or replace function public.remove_shared_recipe'));
    expect(migration, contains('recipe_fingerprint'));
    expect(migration, contains("'recipe_created'"));
    expect(migration, contains('recipe_saves'));
    expect(addRecipe, isNot(contains("title: 'Manuell erstellen'")));
    expect(addRecipe, contains("title: 'Mit ChatGPT erstellen'"));
    expect(addRecipe, contains("title: 'Rezept aus Foto erstellen'"));
    expect(saved, contains("title: const Text('Meine Rezepte')"));
    expect(saved, isNot(contains('receivedRecipeSuggestions')));
    expect(saved, isNot(contains('respondToRecipeSuggestion')));
    expect(saved, isNot(contains("Text('Rezept teilen')")));
    expect(detail, isNot(contains("'Rezept teilen'")));
    expect(detail, contains("'Rezept bearbeiten'"));
    expect(notifications, contains("item.type == 'recipe_created'"));
  });

  test('historical recipe suggestion schema is not deleted by the migration', () {
    final migration = File('supabase/migrations/20260928100000_shared_recipe_collection_v2.sql').readAsStringSync();
    expect(migration, isNot(contains('drop table public.recipe_suggestions')));
    expect(migration, isNot(contains('drop table if exists public.recipe_suggestions')));
  });
}
