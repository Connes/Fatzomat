import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('connected state is compact and hides code and disconnect controls', () {
    final page = File('lib/features/shared/connection_page.dart').readAsStringSync();
    final connectedSection = page.substring(
      page.indexOf('final connected ='),
      page.indexOf('                  : ListView('),
    );

    expect(connectedSection, contains("'Ihr seid verbunden'"));
    expect(connectedSection, contains('Dein Name:'));
    expect(connectedSection, contains('Verbunden mit:'));
    expect(connectedSection, contains('Ihr seid jetzt gemeinsam unterwegs.'));
    expect(connectedSection, isNot(contains('Verbindungscode')));
    expect(connectedSection, isNot(contains('Verbindung trennen')));
    expect(connectedSection, contains('LayoutBuilder'));
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
