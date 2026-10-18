import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('today decision card uses separate header, flexible content and fixed actions', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final cardStart = source.indexOf('class _TodayResultCard');
    final headerStart = source.indexOf('class _TodayDecisionCardHeader');
    final contentStart = source.indexOf('class _TodayDecisionCardContent');
    final actionsStart = source.indexOf('class _TodayDecisionCardActions');
    expect(cardStart, isNonNegative);
    expect(headerStart, greaterThan(cardStart));
    expect(contentStart, greaterThan(headerStart));
    expect(actionsStart, greaterThan(contentStart));

    final card = source.substring(cardStart, headerStart);
    final header = source.substring(headerStart, contentStart);
    final content = source.substring(contentStart, actionsStart);
    final actions = source.substring(actionsStart);

    expect(card, contains('height: _todayDecisionCardHeight(context)'));
    expect(card, contains('_TodayDecisionCardHeader('));
    expect(card, contains('Expanded('));
    expect(card, contains('_TodayDecisionCardContent('));
    expect(card, contains('_TodayDecisionCardActions('));
    expect(card, contains('height: 180'));
    expect(header, contains('modeLabel'));
    expect(header, contains('child: image'));
    expect(content, contains('categoryLabel'));
    expect(content, contains('onTap: onTitleTap'));
    expect(header, isNot(contains('onTap:')));
    expect(content, contains('crossAxisAlignment: CrossAxisAlignment.stretch'));
    expect(content, contains('Expanded('));
    expect(content, contains('child: Center('));
    expect(content, contains('maxLines: 2'));
    expect(content, contains('TextOverflow.ellipsis'));
    expect(actions, contains('height: 58'));
  });

  test('Today decision choices and partner action have separate surfaces', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final start = source.indexOf('class _TodayDecisionCard extends StatelessWidget');
    final end = source.indexOf('class _TodayResultCard extends StatelessWidget', start);
    expect(start, isNonNegative);
    expect(end, greaterThan(start));
    final card = source.substring(start, end);

    expect(card, contains('The four decision modes live together in their own surface.'));
    expect(card, contains('GridView.count('));
    expect(card, contains('The partner-decision action is visually separated from the grid.'));
    expect(card, contains("'Entscheide Du'"));
    expect(card, contains('const SizedBox(height: 12)'));
    expect(source, contains('gridHeight + 16 + 76 + 20 + 8 + 28'));
  });
}
