import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saved recipe selection from cooking explicitly returns to Today', () {
    final shell = File('lib/core/app_shell.dart').readAsStringSync();
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();
    final mode = File('lib/features/food_modes/food_mode_page.dart').readAsStringSync();
    final cooking = File('lib/features/food_modes/cook_next_step_page.dart').readAsStringSync();
    final recipes = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();

    expect(shell, contains('TodayPage(onNavigateToTab: _selectTab)'));
    expect(today, contains('onNavigateToToday: widget.onNavigateToTab == null'));
    expect(mode, contains('onNavigateToToday: widget.onNavigateToToday'));
    expect(cooking, contains('onNavigateToToday: widget.onNavigateToToday'));
    expect(recipes, contains('Navigator.of(context).popUntil((route) => route.isFirst)'));
    expect(recipes, contains('final navigateToToday = widget.onNavigateToToday'));
    expect(recipes, contains('navigateToToday();'));
  });
}
