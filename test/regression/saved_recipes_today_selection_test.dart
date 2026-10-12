import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recipe library uses date selection instead of a Today-specific state', () {
    final source = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();

    expect(source, contains("label: const Text('Auswählen')"));
    expect(source, contains('Future<DateTime?> _choosePlanDate()'));
    expect(source, contains('itemCount: 7'));
    expect(source, contains('enabled: label == null'));
    expect(source, isNot(contains('todayPlan?.isRecipe == true')));
    expect(source, isNot(contains('Für heute ausgewählt')));
    expect(source, isNot(contains('if (hasActiveTodayPlan)')));
  });
}
