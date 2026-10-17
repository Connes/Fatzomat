import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('today decision card keeps heading above image and conditionally shows category', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final card = source.substring(source.indexOf('class _TodayResultCard'), source.indexOf('class _TodayChoiceImage'));
    expect(card.indexOf('modeLabel'), lessThan(card.indexOf('if (plan.isRecipe)')));
    expect(card, contains("if (plan.decisionType != 'order')"));
    expect(card, contains('MainAxisAlignment.spaceBetween'));
    expect(card, contains('padding: const EdgeInsets.only(top: 8)'));
    expect(card, contains('const SizedBox(height: 8),'));
  });
}
