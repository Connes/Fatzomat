import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shopping lists only show days with active recipe decisions', () {
    final page = File('lib/features/shared/multi_day_shopping_list_page.dart').readAsStringSync();

    expect(page, contains('List<DateTime> get _activeDays'));
    expect(page, contains('if (activeDays.isEmpty)'));
    expect(page, contains('for (final day in activeDays)'));
    expect(page, contains('_plans[i].any((plan) => plan.isRecipe)'));
    expect(page, contains('selectedPlanIds.contains(item.planId)'));
  });

  test('ingredient search is removed and shopping content uses opaque surfaces', () {
    final page = File('lib/features/shared/multi_day_shopping_list_page.dart').readAsStringSync();

    expect(page, isNot(contains('Zutaten suchen')));
    expect(page, isNot(contains('_searchController')));
    expect(page, contains('AppSurface('));
    expect(page, contains('color: AppDesign.surface'));
    expect(page, contains('surfaceTintColor: Colors.transparent'));
    expect(page, contains("table: 'personal_today_plans'"));
    expect(page, contains("table: 'shopping_items'"));
    expect(page, contains('load(showLoading: false)'));
  });

  test('cancelled personal decisions clean up their shopping items in the database', () {
    final migration = File('supabase/migrations/20261011190000_cleanup_cancelled_plan_shopping_items.sql')
        .readAsStringSync();

    expect(migration, contains('cleanup_personal_plan_shopping_items'));
    expect(migration, contains("NEW.status = 'cancelled'"));
    expect(migration, contains('DELETE FROM public.shopping_items'));
    expect(migration, contains('personal_today_plan_id = OLD.id'));
  });
}
