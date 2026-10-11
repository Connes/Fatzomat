import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('future recipe details cannot mark a plan as cooked', () {
    final detail = File('lib/features/recipes/recipe_detail_page.dart').readAsStringSync();
    final start = detail.indexOf('Future<void> markCooked() async {');
    final end = detail.indexOf('Future<void> manageRecipeImage()', start);

    expect(start, isNonNegative);
    expect(end, greaterThan(start));
    final method = detail.substring(start, end);
    expect(method, contains('if (!_isPlanDateToday)'));
    expect(method, contains('Zukünftige Entscheidungen können nicht als gekocht markiert werden.'));
    expect(method, contains('personalToday.todayPlan(date: widget.planDate)'));
    expect(method, isNot(contains('final today = await personalToday.todayPlan();')));
    expect(method.indexOf('if (!_isPlanDateToday)'), lessThan(method.indexOf('personalToday.updateStatus')));
  });

  test('database trigger rejects cooked status for future plans on every write path', () {
    final migration = File('supabase/migrations/20261011120000_prevent_future_plan_completion.sql').readAsStringSync();

    expect(migration, contains('CREATE OR REPLACE FUNCTION public.prevent_future_personal_plan_completion()'));
    expect(migration, contains("IF NEW.status = 'cooked' AND NEW.plan_date > current_date THEN"));
    expect(migration, contains('BEFORE INSERT OR UPDATE OF status, plan_date'));
    expect(migration, contains('EXECUTE FUNCTION public.prevent_future_personal_plan_completion()'));
    expect(migration, contains('ERRCODE = \'check_violation\''));
  });

  test('the existing status RPC is date-scoped to the current day', () {
    final repository = File('lib/data/repositories/personal_today_repository.dart').readAsStringSync();
    expect(repository, contains("rpc('update_personal_today_status'"));
    final migration = File('supabase/migrations/20261011120000_prevent_future_plan_completion.sql').readAsStringSync();
    expect(migration, contains('NEW.plan_date > current_date'));
  });
}
