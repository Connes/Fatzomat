import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('day navigation starts today and cannot move into the past', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(today, contains('_selectedDate = _dateOnly(widget.initialDate ?? today);'));
    expect(today, contains('if (_selectedDate.isBefore(today)) _selectedDate = today;'));
    expect(today, contains('if (target.isBefore(today)) return;'));
    expect(today, contains('if (!_isSelectedDateToday)'));
    expect(today, contains("tooltip: 'Vorheriger Tag'"));
    expect(today, contains("tooltip: 'Nächster Tag'"));
  });

  test('horizontal swipes change the selected day from the main content area', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    final refresh = today.indexOf('child: RefreshIndicator');
    final gesture = today.indexOf('child: GestureDetector', refresh);
    final scroll = today.indexOf('child: SingleChildScrollView', gesture);
    expect(refresh, isNonNegative);
    expect(gesture, greaterThan(refresh));
    expect(scroll, greaterThan(gesture));
    expect(today, contains('_shiftSelectedDate(velocity < 0 ? 1 : -1);'));
  });

  test('restaurant discovery receives the selected date before saving a decision', () {
    final foodMode = File('lib/features/food_modes/food_mode_page.dart').readAsStringSync();
    final discoveryStart = foodMode.indexOf('builder: (_) => DiscoveryPage(');
    final discoveryEnd = foodMode.indexOf('),\n      ),', discoveryStart);
    expect(discoveryStart, isNonNegative);
    expect(discoveryEnd, greaterThan(discoveryStart));
    expect(
      foodMode.substring(discoveryStart, discoveryEnd),
      contains('planDate: widget.planDate,'),
    );
    expect(foodMode, contains('date: widget.planDate,'));
  });

  test('saved recipe selection and recipe details keep the selected planning date', () {
    final saved = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();

    expect(saved, contains('today = await personalToday.todayPlan(date: widget.planDate);'));
    expect(RegExp(r'planDate: widget\.planDate').allMatches(saved), hasLength(2));
    expect(saved, contains('date: widget.planDate,'));
    expect(saved, contains("label: Text(_isSelectedDateToday ? 'Für heute auswählen' : 'Für diesen Tag auswählen')"));
  });

  test('the Today app bar displays the selected date and day controls', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(today, contains('String _todayDateLabel() {'));
    expect(today, contains('final date = _dateOnly(_selectedDate);'));
    expect(today, contains('_todayDateLabel(),'));
    expect(today, contains('if (!_isSelectedDateToday)'));
    expect(today, contains('child: AnimatedSwitcher('));
    expect(today, contains('duration: const Duration(milliseconds: 320)'));
    expect(today, contains('FractionalTranslation('));
    expect(today, contains('key: ValueKey<DateTime>(_displayedDate)'));
  });


  test('changing day hides the old plan while the target date loads', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();
    final shiftStart = today.indexOf('void _shiftSelectedDate(int days)');
    final shiftEnd = today.indexOf('void _checkDayBoundary()', shiftStart);
    expect(shiftStart, isNonNegative);
    expect(shiftEnd, greaterThan(shiftStart));
    final shift = today.substring(shiftStart, shiftEnd);
    expect(shift, contains('loading = true;'));
  });

  test('cancelling a plan is scoped by its ID, not by the current date', () {
    final migration = File('supabase/migrations/20261011100000_date_aware_plan_cancellation.sql').readAsStringSync();
    expect(migration, contains("WHERE id = p_plan_id\n    AND user_id = uid\n    AND status = 'planned'"));
    expect(migration, isNot(contains('plan_date = current_date')));
    expect(migration, contains('DELETE FROM public.shopping_items'));
  });

  test('selecting a saved recipe returns to Today', () {
    final saved = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();
    expect(saved, contains('widget.onNavigateToTab!(0);'));
    expect(saved, contains('Navigator.pop(context, true);'));
  });
}
