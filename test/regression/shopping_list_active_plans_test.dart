import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shopping lists only show days with active recipe decisions', () {
    final page = File('lib/features/shared/multi_day_shopping_list_page.dart').readAsStringSync();

    expect(page, contains('List<DateTime> get _activeDays'));
    expect(page, contains('if (activeDays.isEmpty)'));
    expect(page, contains('for (final day in activeDays)'));
    expect(page, contains('_plans[i].where((plan) => plan.isRecipe).any('));
    expect(page, contains('_items.any((item) => item.planId == plan.id)'));
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

  test('day rows show only the date and checked ingredients are struck through', () {
    final page = File('lib/features/shared/multi_day_shopping_list_page.dart').readAsStringSync();

    expect(page, contains('return date;'));
    expect(page, isNot(contains('Zutatenpositionen')));
    expect(page, isNot(contains('geplante Rezepte ·')));
    expect(page, contains('TextDecoration.lineThrough'));
    expect(page, contains("const Text('Einkaufsliste erledigt')"));
    expect(page, contains('_repo.completeShoppingList(planIds)'));
    expect(page, contains('shoppingListCompletedAt != null'));
    expect(page, contains("Text('Erledigt'"));
  });


  test('completed shopping days disappear and the selected-day count is recalculated', () {
    final page = File('lib/features/shared/multi_day_shopping_list_page.dart').readAsStringSync();

    expect(page, contains('_items.any((item) => item.planId == plan.id)'));
    expect(page, contains('_selected.removeWhere((key) => !activeKeys.contains(key))'));
    expect(page, contains("'\${selectedDays.length} von \${activeDays.length} Tagen ausgewählt'"));
    expect(page, contains('await load(showLoading: false);'));
    expect(page, contains('_repo.completeShoppingList(planIds)'));
    expect(page, contains('_isDayCompleted(day)'));
    expect(page, contains("Text('Erledigt'"));
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
}
