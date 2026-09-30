import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Heute ist eine reduzierte Tageskarte', () {
    final shell = File('lib/core/app_shell.dart').readAsStringSync();
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(shell, contains('int index = 0;'));
    expect(shell, contains('const TodayPage()'));
    expect(shell, contains("label: 'Heute'"));
    expect(shell, isNot(contains("label: 'Start'")));
    expect(shell, isNot(contains('const HomePage()')));

    expect(today, contains('backgroundType: TogetherBackgroundType.home'));
    expect(today, contains('respectTopSafeArea: true'));
    expect(today, contains('statusBarIconBrightness: Brightness.dark'));
    expect(today, contains('statusBarBrightness: Brightness.light'));
    expect(today, contains("'Wir kochen'"));
    expect(today, contains("'Wir bestellen'"));
    expect(today, contains("'Wir gehen essen'"));
    expect(today, contains("'Überrasch mich'"));
    expect(today, contains("'Entscheide Du'"));
    expect(today, isNot(contains("'Entscheidung ändern'")));
    expect(today, contains("'Entscheidung entfernen'"));
    expect(today, contains("assets/together/clean/icons/icon_cooking.png"));
    expect(today, contains("assets/together/clean/icons/icon_delivery.png"));
    expect(today, contains("assets/together/clean/icons/icon_restaurant.png"));
    expect(today, contains("assets/together/clean/icons/icon_surprise.png"));
    // "Entscheide Du" is now a durable message, not a DecisionRequest lifecycle.
    expect(today, contains("sendDecisionMessage(type: 'ask')"));
    expect(today, isNot(contains('activeDecisionRequestCreatedByMe')));
    expect(today, isNot(contains('createDecisionRequest(assignedTo: partner)')));
    expect(today, contains("table: 'personal_today_plans'"));

    expect(today, isNot(contains("'Was essen wir heute?'")));
    expect(today, isNot(contains("'HEUTE GIBT’S'")));
    expect(today, isNot(contains("'Gemeinsam entschieden'")));
    expect(today, isNot(contains("'Rezept ansehen'")));
    expect(today, isNot(contains("'Als Nächstes'")));
    expect(today, isNot(contains("'Weitere Möglichkeiten'")));
  });
}
