import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepted recipe sharing creates an independent personal recipe copy', () {
    final migration = File('supabase/migrations/20260924190000_recipe_sharing_independent_copies.sql').readAsStringSync();

    expect(migration, contains('source_recipe public.recipes'));
    expect(migration, contains('insert into public.recipes('));
    expect(migration, contains('created_by, name, description, servings'));
    expect(migration, contains('source_recipe.image_url'));
    expect(migration, contains('insert into public.recipe_ingredients('));
    expect(migration, contains('from public.recipe_ingredients'));
    expect(migration, contains('insert into public.recipe_saves(recipe_id, user_id)'));
    expect(migration, contains("new_status := 'accepted'"));
    expect(migration, contains("new_status := 'declined'"));
    expect(migration, contains('source_recipe.id is null'));
  });

  test('recipe sharing is restricted to the sender own recipes', () {
    final migration = File('supabase/migrations/20260924190000_recipe_sharing_independent_copies.sql').readAsStringSync();
    expect(migration, contains('and r.created_by = uid'));
    expect(migration, contains("raise exception 'Du kannst nur eigene Rezepte teilen.'"));
  });
}
