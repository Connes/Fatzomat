import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Single Modus sperrt Entscheide Du ohne Connection und bietet Verbindung an', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(today, contains('bool _hasConnection = false;'));
    expect(today, contains("final connected = connection?.isConnected == true;"));
    expect(today, contains("title: const Text('Keine Verbindung vorhanden')"));
    expect(today, contains("label: const Text('Verbindung erstellen')"));
    expect(today, contains("MaterialPageRoute(builder: (_) => const ConnectionPage())"));
    expect(today, contains('onPressed: hasConnection ? onDecide : null'));
    expect(today, isNot(contains("Without a Connection, 'Entscheide Du' remains a valid personal")));
  });
}
