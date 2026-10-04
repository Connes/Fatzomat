import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;
  String read(String relative) => File('$root/$relative').readAsStringSync();

  test('personal Today supports non-recipe decision persistence', () {
    final migration = read('supabase/migrations/20260920110000_personal_today_decision_types.sql');
    final repo = read('lib/data/repositories/personal_today_repository.dart');
    final model = read('lib/data/models/today_plan.dart');
    final today = read('lib/features/shared/today_page.dart');
    expect(migration, contains("decision_type in ('recipe','order','dine_out','surprise')"));
    expect(migration, contains('set_personal_today_decision'));
    expect(repo, contains('selectDecision'));
    expect(repo, contains("'p_decision_type'"));
    expect(model, contains('decisionType'));
    expect(model, contains('decisionValue'));
    expect(today, contains("await _openSurprise();"));
  });

  test('collaboration recipe decision does not also write personal Today', () {
    final addRecipe = read('lib/features/recipes/add_recipe_page.dart');
    final savedRecipes = read('lib/features/recipes/saved_recipes_page.dart');
    expect(addRecipe, contains('widget.selectForToday && widget.decisionRequestId == null'));
    expect(savedRecipes, contains('if (widget.decisionRequestId == null)'));
  });

  test('Today recipe card only opens RecipeDetail for recipe decisions', () {
    final today = read('lib/features/shared/today_page.dart');
    expect(today, contains('plan!.isRecipe'));
    expect(today, contains('RecipeDetailPage('));
    expect(today, contains('recipeId: plan!.recipeId!'));
    expect(today, contains('onTodayPlanChanged: load'));
    expect(today, contains("onOpenRecipe: plan!.isRecipe && plan!.status != 'cooked'"));
    expect(today, contains('final VoidCallback? onOpenRecipe;'));
    expect(today, contains("label: const Text('Entscheidung entfernen')"));
  });
}
