import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('connected state is compact and hides code and disconnect controls', () {
    final page = File('lib/features/shared/connection_page.dart').readAsStringSync();

    expect(page, contains("Text(\n                                        'Ihr seid verbunden'"));
    expect(page, contains("'Dein Name: ${info!.myDisplayName}'"));
    expect(page, contains("'Verbunden mit: ${info!.partnerDisplayName}'"));
    expect(page, contains('Ihr seid jetzt gemeinsam unterwegs.'));
    expect(page, contains('connected\n                  ? LayoutBuilder'));
    expect(page, isNot(contains("const Text('Verbindungscode')")));
    expect(page, isNot(contains("label: const Text('Verbindung trennen')")));
    expect(page, contains('callback: (_) => load()'));
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
