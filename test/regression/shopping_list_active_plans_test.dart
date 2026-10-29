import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shopping lists only show days with active recipe decisions', () {
    final page = File('lib/features/shared/multi_day_shopping_list_page.dart').readAsStringSync();

    expect(page, contains('List<DateTime> get _activeDays'));
    expect(page, contains('if (activeDays.isEmpty)'));
    expect(page, contains('for (final day in activeDays)'));
    expect(page, contains('_plans[i].any((plan) => plan.isRecipe)'));
    expect(page, contains('_items.any((item) => item.planId == plan.id)'));
    expect(page, contains('selectedPlanIds.contains(item.planId)'));
  });

  test('planned recipe dates remain visible even if shopping rows are missing', () {
    final page = File('lib/features/shared/multi_day_shopping_list_page.dart').readAsStringSync();

    expect(page, contains('Keep a planned recipe date visible even if its shopping rows'));
    expect(page, contains('_plans[i].any((plan) => plan.isRecipe)'));
    expect(page, contains('final personalDays = await _repo.plannedShoppingDates();'));
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

  test('day rows show only the date and checked ingredients are struck through', () {
    final page = File('lib/features/shared/multi_day_shopping_list_page.dart').readAsStringSync();

    expect(page, contains('return date;'));
    expect(page, isNot(contains('Zutatenpositionen')));
    expect(page, isNot(contains('geplante Rezepte ·')));
    expect(page, contains('TextDecoration.lineThrough'));
    expect(page, contains("const Text('Einkaufsliste erledigen')"));
    expect(page, contains('_repo.completeShoppingList'));
  });


  test('completed shopping days remain visible and can be reopened', () {
    final page = File('lib/features/shared/multi_day_shopping_list_page.dart').readAsStringSync();

    expect(page, contains('_items.any((item) => item.planId == plan.id)'));
    expect(page, contains('_selected.removeWhere((key) =>'));
    expect(page, contains('!_isDayCompleted(day)'));
    expect(page, contains('onChanged: _isDayCompleted(day)'));
    expect(page, contains("'\${selectedDays.length} von \${activeDays.length} Tagen ausgewählt'"));
    expect(page, contains('await load(showLoading: false);'));
    expect(page, contains('_isDayCompleted(day)'));
    expect(page, contains("const Text('Erledigt')"));
    expect(page, isNot(contains('_repo.deleteShoppingItem(item.id)')));
  });

  test('shopping list loads every planned recipe date instead of a fixed three-day window', () {
    final repository = File('lib/data/repositories/personal_today_repository.dart').readAsStringSync();
    final page = File('lib/features/shared/multi_day_shopping_list_page.dart').readAsStringSync();

    expect(repository, contains('Future<List<DateTime>> plannedShoppingDates()'));
    expect(repository, contains(".eq('decision_type', 'recipe')"));
    expect(repository, contains(".eq('status', 'planned')"));
    expect(repository, contains(".gte('plan_date', today)"));
    expect(page, contains('final personalDays = await _repo.plannedShoppingDates();'));
    expect(page, contains('_days = days;'));
    expect(page, isNot(contains('List.generate(3')));
    expect(page, isNot(contains('new three-day view')));
  });

  test('shopping list completion requires every aggregated ingredient to be checked', () {
    final page = File('lib/features/shared/multi_day_shopping_list_page.dart').readAsStringSync();

    expect(page, contains('items.any((item) => !item.checked)'));
    expect(page, contains('aggregated.isNotEmpty && aggregated.every((item) => item.checked)'));
    expect(page, contains('onPressed: _completingList || !canCompleteList'));
    expect(page, contains('Hake zuerst alle Zutaten ab, um die Einkaufsliste abzuschließen.'));
  });

  test('cancelled personal decisions clean up their shopping items in the database', () {
    final migration = File('supabase/migrations/20261011190000_cleanup_cancelled_plan_shopping_items.sql')
        .readAsStringSync();

    expect(migration, contains('cleanup_personal_plan_shopping_items'));
    expect(migration, contains("NEW.status = 'cancelled'"));
    expect(migration, contains('DELETE FROM public.shopping_items'));
    expect(migration, contains('personal_today_plan_id = OLD.id'));
    expect(migration, contains('REVOKE ALL ON FUNCTION'));
  });
  test('accepted shared recipes are represented in the unified shopping list', () {
    final repository = File('lib/data/repositories/personal_today_repository.dart').readAsStringSync();
    final collaboration = File('lib/data/repositories/collaboration_repository.dart').readAsStringSync();
    final page = File('lib/features/shared/multi_day_shopping_list_page.dart').readAsStringSync();

    expect(repository, contains("from('decision_shares')"));
    expect(repository, contains("map['is_shared_accepted'] = activeShares.any"));
    expect(page, contains('.where((plan) => !plan.isSharedAccepted)'));
    expect(collaboration, contains('Future<List<Map<String, dynamic>>> sharedRecipePlans({DateTime? fromDate})'));
    expect(page, contains('_collaboration.sharedRecipePlans('));
    expect(page, contains('recipe[\'image_url\']?.toString()'));
    expect(page, contains('sharedPlanIds.add(id)'));
    expect(page, contains('final sharedPlanIds = <String>{}'));
    expect(page, contains('Icons.people_alt_rounded'));
  });

}
