import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Today refreshes immediately when recipe detail selects the current recipe for today', () {
    final detail = File('lib/features/recipes/recipe_detail_page.dart').readAsStringSync();
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(detail, contains('final Future<void> Function()? onTodayPlanChanged;'));
    expect(detail, contains('await widget.onTodayPlanChanged?.call();'));
    expect(today, contains('onTodayPlanChanged: load,'));
    expect(today, contains('if (mounted) await load();'));
  });
}
