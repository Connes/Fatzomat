import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('day navigation starts today and cannot move into the past', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(today, contains('_selectedDate = _dateOnly(widget.initialDate ?? today);'));
    expect(today, contains('if (_selectedDate.isBefore(today)) _selectedDate = today;'));
    expect(today, contains('if (target.isBefore(today)) return;'));
    expect(today, contains('final showBackwardControls = !_isSelectedDateToday;'));
    expect(today, contains('final showBackwardControls = !_isSelectedDateToday;'));
    expect(today, contains('alignment: Alignment.centerLeft'));
    expect(today, contains('alignment: Alignment.centerRight'));
    expect(today, contains('child: Stack('));
    expect(today, contains("tooltip: 'Vorheriger Tag'"));
    expect(today, contains("tooltip: 'Nächster Tag'"));
  });

  test('double arrows jump between open decisions and keep Today as the backward boundary', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();
    final repository = File('lib/data/repositories/personal_today_repository.dart').readAsStringSync();

    expect(today, contains("tooltip: 'Vorherige offene Entscheidung'"));
    expect(today, contains("tooltip: 'Nächste offene Entscheidung'"));
    expect(today, contains('Icons.keyboard_double_arrow_left'));
    expect(today, contains('Icons.keyboard_double_arrow_right'));
    expect(today, contains('_jumpToOpenDecision(forward: false)'));
    expect(today, contains('_jumpToOpenDecision(forward: true)'));
    expect(repository, contains(".eq('status', 'planned')"));
    expect(repository, contains(".gt('plan_date', from)"));
    expect(repository, contains(".gte('plan_date', today)"));
    expect(repository, contains('if (row == null) return DateTime(todayDate.year, todayDate.month, todayDate.day);'));
  });

  test('horizontal swipes change the selected day from the main content area', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    final refresh = today.indexOf('child: RefreshIndicator');
    final gesture = today.indexOf('child: GestureDetector', refresh);
    final scroll = today.indexOf('child: SingleChildScrollView', gesture);
    expect(refresh, isNonNegative);
    expect(gesture, greaterThan(refresh));
    expect(scroll, greaterThan(gesture));
    expect(today, contains('onHorizontalDragUpdate: (details)'));
    expect(today, contains('_dragOffset = (_dragOffset + details.delta.dx).clamp('));
    expect(today, contains('final shouldChangeDate = draggedFarEnough || flicked;'));
    expect(today, contains('_shiftSelectedDate(direction)'));
    expect(today, contains('Transform.translate('));
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
    expect(saved, contains('date: planDate,'));
    expect(saved, contains("label: const Text('Auswählen')"));
  });

  test('date label uses compact German weekday abbreviations and full month names', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(today, contains("const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];"));
    expect(today, contains("return '\${weekdays[date.weekday - 1]}, \${date.day}. \${months[date.month - 1]}';"));
    expect(today, contains('softWrap: false'));
    expect(today, contains('overflow: TextOverflow.visible'));
  });

  test('the Today app bar displays the selected date and day controls', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(today, contains('String _todayDateLabel() {'));
    expect(today, contains('final date = _dateOnly(_selectedDate);'));
    expect(today, contains('_todayDateLabel(),'));
    expect(today, contains('final showBackwardControls = !_isSelectedDateToday;'));
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
    expect(today.substring(shiftStart, shiftEnd), contains('loading = true;'));
  });

  test('cancelling a plan is scoped by its ID, not by the current date', () {
    final migration = File('supabase/migrations/20261011100000_date_aware_plan_cancellation.sql').readAsStringSync();
    expect(migration, contains('WHERE id = p_plan_id'));
    expect(migration, contains('AND user_id = uid'));
    expect(migration, contains("AND status = 'planned'"));
    final functionBody = migration.substring(migration.indexOf('BEGIN'));
    expect(functionBody, isNot(contains('plan_date = current_date')));
    expect(migration, contains('DELETE FROM public.shopping_items'));
  });

  test('selecting a saved recipe returns to Today', () {
    final saved = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();
    expect(saved, contains('widget.onNavigateToTab!(0);'));
    expect(saved, contains('Navigator.pop(context, true);'));
  });
}
