import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V18 macht Heute zum zentralen Einstieg und zur Tageskarte', () {
    final shell = File('lib/core/app_shell.dart').readAsStringSync();
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('version: 1.13.40+252'));
    expect(shell, contains('int index = 0;'));
    expect(shell, contains("NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Heute')"));
    expect(shell, contains('const TodayPage()'));
    expect(today, isNot(contains("'Entscheidung ändern'")));
    expect(today, contains("'Entscheidung entfernen'"));
    expect(today, contains("'Wir kochen'"));
    expect(today, contains("'Wir bestellen'"));
    expect(today, contains("'Wir gehen essen'"));
    expect(today, contains("'Überrasch mich'"));
    expect(today, contains("'Entscheide Du'"));
    expect(today, contains('PreferredSizeWidget _todayAppBar()'));
    expect(today, contains("automaticallyImplyLeading: false"));
    expect(today, contains("_todayDateLabel()"));
    expect(today, isNot(contains('class _TodayDateLabel')));
    expect(today, contains('class _TodayDecisionCard'));
    expect(today, contains('class _TodayResultCard'));

    expect(today, isNot(contains("'Was essen wir heute?'")));
    expect(today, isNot(contains("'HEUTE GIBT’S'")));
    expect(today, isNot(contains("'Aus meinen Rezepten auswählen'")));
    expect(today, isNot(contains("'Neues Rezept mit ChatGPT erstellen'")));
  });
}
