import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('personal Today flow has no connection dependency', () {
    final today = File('lib/features/shared/controllers/today_controller.dart').readAsStringSync();
    final personal = File('lib/data/repositories/personal_today_repository.dart').readAsStringSync();
    final collaboration = File('lib/data/repositories/collaboration_repository.dart').readAsStringSync();

    expect(today, contains('PersonalTodayRepository'));
    expect(today, isNot(contains('CollaborationRepository')));
    expect(personal, contains("from('personal_today_plans')"));
    expect(personal, contains("rpc('set_personal_today_plan'"));
    expect(personal, isNot(contains('current_connection_id')));
    expect(personal, isNot(contains('shared_recipe_plans')));
    expect(collaboration, contains('shareRecipeForToday'));
    expect(collaboration, isNot(contains('selectRecipeForToday')));
    expect(collaboration, isNot(contains('Future<TodayPlan?> todayPlan')));
  });

  test('personal recipe import does not require a connection', () {
    final source = File('lib/features/recipes/add_recipe_page.dart').readAsStringSync();
    expect(source, contains('PersonalTodayRepository().selectRecipeForToday'));
    expect(source, isNot(contains('_ensureConnectionForToday')));
  });

  test('shopping has explicit personal/shared ownership columns', () {
    final migration = File('supabase/migrations/202609200001_personal_first_today_and_shopping.sql').readAsStringSync();
    expect(migration, contains('personal_today_plan_id'));
    expect(migration, contains('shopping_items_exactly_one_plan'));
    expect(migration, contains('personal_today_plans_one_active_per_user_day'));
    expect(migration, contains('personal today own select'));
    expect(migration, contains('shared_recipe_plans'));
    final invokerMigration = File('supabase/migrations/202609200002_personal_today_invoker_functions.sql').readAsStringSync();
    expect(invokerMigration, contains('security invoker'));
  });
}
