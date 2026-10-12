import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Lieferbestellung erfordert ausdrückliche Bestätigung', () {
    final source = File('lib/features/food_modes/delivery_services_page.dart').readAsStringSync();

    expect(source, contains("label: const Text('Bestellung abschließen')"));
    expect(source, contains("onPressed: () => _confirmOrderCompletion(context)"));
    expect(source, contains("title: const Text('Bestellung abschließen?')"));
    expect(source, contains("content: const Text('Möchtest du die Bestellung wirklich abschließen?')"));
    expect(source, contains("child: const Text('Abbrechen')"));
    expect(source, contains("child: const Text('Bestätigen')"));
    expect(source, contains('if (confirmed != true || !context.mounted) return;'));
    expect(source, contains("await _completeOrder(context);"));
    expect(source, contains("PersonalTodayRepository().updateStatus(planId, 'cooked')"));
  });
}
