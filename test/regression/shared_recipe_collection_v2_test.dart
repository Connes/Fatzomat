import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared recipe collection has secure two-person access, duplicate protection and realtime', () {
    final migration = File('supabase/migrations/20260928100000_shared_recipe_collection_v2.sql').readAsStringSync();
    final repo = File('lib/data/repositories/recipe_repository.dart').readAsStringSync();
    final deleteMigration = File('supabase/migrations/20260929133509_harden_recipe_delete.sql').readAsStringSync();
    final model = File('lib/data/models/recipe.dart').readAsStringSync();
    final saved = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();

    expect(migration, contains('alter table public.recipes'));
    expect(migration, contains('add column if not exists updated_at'));
    expect(migration, contains('add column if not exists recipe_fingerprint'));
    expect(migration, contains('recipes connection collection read'));
    expect(migration, contains('recipe ingredients connection collection read'));
    expect(migration, contains('create or replace function public.find_shared_recipe_duplicate'));
    expect(migration, contains('create or replace function public.create_shared_recipe'));
    expect(migration, contains('create or replace function public.update_shared_recipe'));
    expect(migration, contains('alter publication supabase_realtime add table public.recipes'));
    expect(migration, contains("'recipe_created'"));
    expect(migration, contains('p_allow_duplicate'));

    expect(repo, contains('find_shared_recipe_duplicate'));
    expect(repo, contains('create_shared_recipe'));
    expect(repo, contains('update_shared_recipe'));
    expect(repo, contains('remove_recipe_from_collection'));
    expect(deleteMigration, contains('create or replace function public.remove_recipe_from_collection'));
    expect(repo, contains('RecipeDuplicateException'));
    expect(model, contains('updatedAt'));
    expect(saved, contains("table: 'recipes'"));
    expect(saved, contains("title: const Text('Unsere Rezepte')"));
  });
}
