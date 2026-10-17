import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('today decision card puts mode above image and category under image', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final card = source.substring(source.indexOf('class _TodayResultCard'), source.indexOf('class _TodayChoiceImage'));
    expect(card.indexOf('modeLabel'), lessThan(card.indexOf('if (plan.isRecipe)')));
    expect(card.indexOf("? plan.decisionValue\n                                    : plan.isRecipe"), greaterThan(card.indexOf('if (plan.isRecipe)')));
    expect(card, contains('MainAxisAlignment.spaceBetween'));
  });
}
