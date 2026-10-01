import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V85 sends a durable decision message from Home', () {
    final home = File('lib/features/home/home_page.dart').readAsStringSync();
    final notifications = File('lib/features/settings/notifications_page.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('version: 1.13.46+260'));
    expect(home, contains("sendDecisionMessage(type: 'ask')"));
    expect(home, contains("label: FittedBox"));
    expect(home, contains("'Entscheide Du'"));
    expect(home, isNot(contains("table: 'decision_requests'")));
    expect(notifications, contains('decisionShareId'));
    expect(notifications, contains('DecisionSharePage'));
  });
}
