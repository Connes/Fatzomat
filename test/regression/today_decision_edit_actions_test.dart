import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Today decision edit action routes ordering and dining out to their matching modes', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(source, contains("case 'order':\n        await _openMode(FoodMode.order);"));
    expect(source, contains("case 'dine_out':\n        await _openMode(FoodMode.dineOut);"));
    expect(source, contains('await _openMenuBuilder();'));
    expect(source, contains('onEditDecision: _editTodayDecision'));
  });

  test('Today result card exposes the edit action in its top-right header', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(source, contains("tooltip: 'Tagesentscheidung ändern'"));
    expect(source, contains('onPressed: onEditDecision'));
    expect(source, contains('if (onEditDecision != null)'));
  });
}
