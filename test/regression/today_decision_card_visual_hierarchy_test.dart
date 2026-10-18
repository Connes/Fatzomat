import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('today decision card uses larger headings and taller images', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final card = source.substring(source.indexOf('class _TodayResultCard'), source.indexOf('class _TodayChoiceImage'));
    expect(card, contains('fontSize: 18,'));
    expect(card, contains('height: 180,'));
    expect(card, contains("if (plan.decisionType != 'order')"));
    expect(card, contains('padding: const EdgeInsets.only(top: 8)'));
    expect(card, contains('height: 190,\n                          child: Center('));
    expect(card, contains('height: 58,\n                      color: AppDesign.divider,'));
  });
}
