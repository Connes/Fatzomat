import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('connected state avoids redundant status copy and manual refresh action', () {
    final page = File('lib/features/shared/connection_page.dart').readAsStringSync();

    expect(page, contains("Text(memberCount >= 2 ? 'Ihr seid verbunden' : 'Verbindung bereit'"));
    expect(page, contains("'Der Code kann auf dem zweiten Gerät eingegeben werden.'"));
    expect(page, isNot(contains('2 Personen nutzen jetzt dieselbe gemeinsame Sammlung.')));
    expect(page, isNot(contains('Status prüfen')));
    expect(page, contains('callback: (_) => load()'));
    expect(page, contains('OutlinedButton.icon(onPressed: working ? null : disconnect'));
  });

  test('creating a connection from Today stays in the pushed connection page', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();
    final page = File('lib/features/shared/connection_page.dart').readAsStringSync();

    expect(today, contains('MaterialPageRoute(builder: (_) => const ConnectionPage())'));
    expect(page, contains('Future<void> create() async'));
    expect(page, contains('final c = await repo.createConnection(name)'));
    expect(page, contains('setState(() {'));
    expect(page, contains('myCode = c;'));
  });
}
