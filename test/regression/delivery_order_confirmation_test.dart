import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delivery order completion asks for confirmation before changing status', () {
    final page = File('lib/features/food_modes/delivery_services_page.dart').readAsStringSync();

    expect(page, contains("label: const Text('Bestellung abschließen?')"));
    expect(page, contains("title: const Text('Bestellung abschließen?')"));
    expect(page, contains("child: const Text('Abbrechen')"));
    expect(page, contains("child: const Text('Bestellung abschließen')"));
    expect(page, contains('if (confirmed != true || !context.mounted) return;'));
    expect(page, contains('await _completeOrder(context);'));
    expect(page, contains("updateStatus(planId, 'cooked')"));
    expect(page, isNot(contains("onPressed: () => _completeOrder(context),")));
  });
}
