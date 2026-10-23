import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Today date navigation advances by calendar day, not elapsed 24 hours', () {
    final todayPage = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(todayPage, contains('final target = DateTime('));
    expect(todayPage, contains('_selectedDate.day + days,'));
    expect(
      todayPage,
      isNot(contains('_selectedDate.add(Duration(days: days))')),
    );
  });
}
