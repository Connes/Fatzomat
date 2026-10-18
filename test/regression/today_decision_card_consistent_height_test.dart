import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Today decision card keeps the same responsive height before and after selection', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(today, contains('double _todayDecisionCardHeight(BuildContext context)'));
    expect(today, contains('height: _todayDecisionCardHeight(context)'));
    final decisionCardStart = today.indexOf('class _TodayDecisionCard extends StatelessWidget');
    final resultCardStart = today.indexOf('class _TodayResultCard extends StatelessWidget');
    final choiceCardStart = today.indexOf('class _TodayChoiceImage extends StatelessWidget');
    expect(decisionCardStart, isNonNegative);
    expect(resultCardStart, greaterThan(decisionCardStart));
    expect(choiceCardStart, greaterThan(resultCardStart));

    final decisionCard = today.substring(decisionCardStart, resultCardStart);
    final resultCard = today.substring(resultCardStart, choiceCardStart);
    expect(decisionCard, contains('height: _todayDecisionCardHeight(context)'));
    expect(resultCard, contains('height: _todayDecisionCardHeight(context)'));
    expect(resultCard, contains('_TodayDecisionCardHeader('));
    expect(resultCard, contains('Expanded('));
    expect(resultCard, contains('_TodayDecisionCardActions('));
  });
}
