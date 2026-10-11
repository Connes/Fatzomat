import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('day navigation starts today and cannot move into the past', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(today, contains('_selectedDate = _dateOnly(widget.initialDate ?? today);'));
    expect(today, contains('if (_selectedDate.isBefore(today)) _selectedDate = today;'));
    expect(today, contains('if (target.isBefore(today)) return;'));
    expect(today, contains('onPressed: _dateOnly(_selectedDate).isAtSameMomentAs(_dateOnly(DateTime.now()))'));
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

  test('saved recipe selection and recipe details keep the selected planning date', () {
    final saved = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();

    expect(saved, contains('today = await personalToday.todayPlan(date: widget.planDate);'));
    expect(RegExp(r'planDate: widget\.planDate').allMatches(saved), hasLength(2));
    expect(saved, contains('date: widget.planDate,'));
    expect(saved, contains("label: Text(_isSelectedDateToday ? 'Für heute auswählen' : 'Für diesen Tag auswählen')"));
  });

  test('the Today app bar displays the selected date, not always the current date', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(today, contains('String _todayDateLabel() {'));
    expect(today, contains('final date = _dateOnly(_selectedDate);'));
    expect(today, contains('title: Text(\n        _todayDateLabel(),'));
  });
}
