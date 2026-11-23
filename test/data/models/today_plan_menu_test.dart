import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/data/models/today_plan.dart';

void main() {
  test('TodayPlan reads optional starter and dessert from menu metadata', () {
    final plan = TodayPlan.fromMap({
      'id': 'plan-1',
      'recipe_id': 'main-1',
      'decision_type': 'recipe',
      'decision_value': jsonEncode({
        'type': 'fatzomat_menu',
        'version': 1,
        'courses': [
          {'course': 'starter', 'recipe_id': 'starter-1', 'name': 'Bruschetta'},
          {'course': 'dessert', 'recipe_id': 'dessert-1', 'name': 'Panna Cotta'},
        ],
      }),
      'status': 'planned',
      'servings': 2,
      'recipes': {'name': 'Bolognese'},
    });

    expect(plan.isRecipe, isTrue);
    expect(plan.menuCourses, hasLength(2));
    expect(plan.menuCourses.first['name'], 'Bruschetta');
    expect(plan.menuCourses.last['course'], 'dessert');
  });

  test('TodayPlan ignores non-menu decision values', () {
    final plan = TodayPlan.fromMap({
      'id': 'plan-2',
      'recipe_id': 'main-2',
      'decision_type': 'recipe',
      'decision_value': 'legacy value',
      'status': 'planned',
      'servings': 2,
      'recipes': {'name': 'Pasta'},
    });

    expect(plan.menuCourses, isEmpty);
  });
}
