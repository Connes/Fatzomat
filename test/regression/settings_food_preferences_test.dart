import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;
  String read(String relative) => File('$root/$relative').readAsStringSync();

  test('Einstellungen contains no longer the removed Schmackofatz help box', () {
    final source = read('lib/features/settings/settings_page.dart');

    expect(source, isNot(contains('Über Schmackofatz')));
    expect(
      source,
      isNot(contains('Schmackofatz hilft euch dabei, schneller zu entscheiden')),
    );
  });

  test('Meine Lebensmittel uses one bounded, vertically scrollable list box', () {
    final source = read('lib/features/foods/food_preferences_page.dart');

    expect(source, contains("ValueKey<String>('food_preferences_list_box')"));
    expect(source, contains('AppSurface('));
    expect(source, contains('Scrollbar('));
    expect(source, contains('thumbVisibility: true'));
    expect(source, contains('ListView.builder('));
    expect(source, contains('clamp(140.0, 420.0)'));
    expect(source, contains("ValueKey<String>('food_preferences_empty_state_box')"));
    expect(source, contains('padding: const EdgeInsets.fromLTRB(0, 4, 0, 12)'));
    expect(source, isNot(contains('shrinkWrap: true')));
  });

  test('Personal recipe selection keeps explicit recipe authorization', () {
    final migration = read(
      'supabase/migrations/20260921145714_fix_personal_today_recipe_selection.sql',
    );

    expect(migration, contains('security definer'));
    expect(migration, contains('uid uuid := auth.uid()'));
    expect(migration, contains('r.created_by = uid'));
    expect(migration, contains('rs.user_id = uid'));
    expect(migration, isNot(contains('p_user_id')));
    expect(migration, contains('personal_today_plans'));
    expect(migration, contains('personal_decision_history'));
    expect(migration, contains("source = 'recipe'"));
    expect(migration, contains('grant execute on function public.set_personal_today_plan'));
  });

  test('Personal Today final fix removes the recursive recipe RLS path and restores invoker RPCs', () {
    final migration = read(
      'supabase/migrations/20260921145849_fix_personal_today_rls_recursion.sql',
    );

    expect(migration, contains('create schema if not exists private'));
    expect(migration, contains('private.has_personal_recipe_reference'));
    expect(migration, contains('security definer'));
    expect(migration, contains('recipes resolved decision read'));
    expect(migration, contains('recipe ingredients resolved decision read'));
    expect(migration, contains('alter function public.set_personal_today_plan(uuid, integer) security invoker'));
  });

  test('Personal recipe selection still uses the canonical personal Today RPC', () {
    final repository = read('lib/data/repositories/personal_today_repository.dart');
    final savedRecipes = read('lib/features/recipes/saved_recipes_page.dart');

    expect(repository, contains("rpc('set_personal_today_plan'"));
    expect(repository, contains("'p_recipe_id': recipeId"));
    expect(repository, contains("'p_servings': servings"));
    expect(savedRecipes, contains('personalToday.selectRecipeForToday'));
    expect(savedRecipes, contains("label: const Text('Für heute auswählen')"));
  });
}
