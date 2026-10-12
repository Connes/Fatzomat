import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saved recipe selection offers seven dates and disables occupied days', () {
    final page = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();

    expect(page, contains('Für welchen Tag möchtest du kochen?'));
    expect(page, contains('itemCount: 7'));
    expect(page, contains('enabled: label == null'));
    expect(page, contains("Text('Belegt · \$label')"));
    expect(page, contains("label: const Text('Auswählen')"));
    expect(page, isNot(contains("Text('Für dich \${_selectedDayLabel}')")));
  });

  test('availability includes personal decisions and active shared recipe plans', () {
    final repository = File('lib/data/repositories/personal_today_repository.dart').readAsStringSync();

    expect(repository, contains('Future<Map<String, String>> plannedDayLabels'));
    expect(repository, contains(".from('personal_today_plans')"));
    expect(repository, contains(".from('shared_recipe_plans')"));
    expect(repository, contains('TodayPlan.fromMap(map).displayTitle'));
  });

  test('date-aware recipe planning rejects occupied days instead of updating them', () {
    final migration = File('supabase/migrations/20261012100000_prevent_overwriting_planned_days.sql')
        .readAsStringSync();

    expect(migration, contains('pg_advisory_xact_lock'));
    expect(migration, contains('Dieser Tag ist bereits verplant'));
    expect(migration, contains('public.shared_recipe_plans'));
    expect(migration, isNot(contains('UPDATE public.personal_today_plans')));
  });
}
