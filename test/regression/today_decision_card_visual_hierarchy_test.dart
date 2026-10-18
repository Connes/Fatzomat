import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('today decision card uses a clear fixed header and flexible title hierarchy', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final headerStart = source.indexOf('class _TodayDecisionCardHeader');
    final contentStart = source.indexOf('class _TodayDecisionCardContent');
    final actionsStart = source.indexOf('class _TodayDecisionCardActions');
    expect(headerStart, isNonNegative);
    expect(contentStart, greaterThan(headerStart));
    expect(actionsStart, greaterThan(contentStart));

    final header = source.substring(headerStart, contentStart);
    final content = source.substring(contentStart, actionsStart);
    expect(header, contains('fontSize: 18,'));
    expect(header, contains('height: 180'));
    expect(content, contains('maxLines: 2'));
    expect(content, contains('TextOverflow.ellipsis'));
  });
}
