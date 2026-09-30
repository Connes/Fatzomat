import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Heute zeigt das dynamische Datum ausschließlich in der Today-AppBar', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();
    final shell = File('lib/core/app_shell.dart').readAsStringSync();

    expect(today, contains("String _todayDateLabel()"));
    expect(today, contains("PreferredSizeWidget _todayAppBar()"));
    expect(today, contains("automaticallyImplyLeading: false"));
    expect(today, contains("title: Text("));
    expect(today, contains("_todayDateLabel()"));

    // Das Datum darf nicht mehr als eigenes Widget innerhalb der Today-Karten erscheinen.
    expect(today, isNot(contains("class _TodayDateLabel")));

    // Die anderen Hauptseiten erhalten die Datumsanzeige nicht über die AppShell.
    expect(shell, isNot(contains("_todayDateLabel")));
    expect(shell, isNot(contains("todayDate")));
  });
}
