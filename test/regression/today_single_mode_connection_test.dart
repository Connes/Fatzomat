import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Entscheide Du bleibt ohne Connection klickbar und bietet Verbindung an', () {
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(today, contains("final connected = connection?.isConnected == true;"));
    expect(today, contains("title: const Text('Keine Verbindung vorhanden')"));
    expect(today, contains("label: const Text('Jetzt Connection aufbauen')"));
    expect(today, contains("MaterialPageRoute(builder: (_) => const ConnectionPage())"));
    expect(today, contains('onPressed: onDecide'));
    expect(today, contains('Noch keine Connection vorhanden.'));
  });
}
