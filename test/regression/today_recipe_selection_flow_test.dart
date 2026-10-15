import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Today recipe selection is personal and shared decision resolution stays collaboration-only', () {
    final personal = File('lib/data/repositories/personal_today_repository.dart').readAsStringSync();
    final collaboration = File('lib/data/repositories/collaboration_repository.dart').readAsStringSync();
    final importSource = File('lib/features/recipes/add_recipe_page.dart').readAsStringSync();
    final savedSource = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();
    final todaySource = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(personal, contains("from('personal_today_plans')"));
    expect(personal, contains("rpc('set_personal_plan_for_date'"));
    expect(personal, isNot(contains('current_connection_id')));
    expect(personal, contains('plannedDayLabels'));
    expect(personal, contains('shared_recipe_plans'));

    expect(importSource, contains('selectForToday: widget.selectForToday || widget.decisionRequestId != null'));
    expect(importSource, isNot(contains('_ensureConnectionForToday')));
    expect(importSource, contains('PersonalTodayRepository().selectRecipeForToday'));

    expect(savedSource, contains("label: const Text('Auswählen')"));
    expect(savedSource, contains('PersonalTodayRepository'));
    expect(savedSource, contains('personalToday.selectRecipeForToday'));
    expect(savedSource, isNot(contains('_ensureConnectionForToday')));
    expect(savedSource, contains('if (widget.onNavigateToTab != null)'));
    expect(savedSource, contains('widget.onNavigateToTab!(0);'));
    expect(
      savedSource,
      contains('if (navigator.canPop())'),
      reason: 'Only pop a successful recipe-selection route when the Navigator actually has a route to pop.',
    );

    expect(todaySource, contains('final repo = PersonalTodayRepository();'));
    expect(todaySource, contains("table: 'personal_today_plans'"));
    expect(todaySource, contains('if (selected == true && mounted) await load();'));

    expect(collaboration, contains('Future<String> shareRecipeForToday'));
    expect(collaboration, contains('Future<void> resolveDecisionRequest'));
  });
}
