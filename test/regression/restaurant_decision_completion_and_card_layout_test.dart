import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restaurant completion updates status and refreshes Today', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final start = source.indexOf("extraActionLabel: 'Als erledigt markieren'");
    final end = source.indexOf('onOpenRecipe:', start);
    final action = source.substring(start, end);
    expect(action, contains("repo.updateStatus(plan!.id, 'cooked')"));
    expect(action, isNot(contains('repo.removeTodayPlan(plan!.id)')));
    expect(action, contains('await load()'));
  });

  test('order title is centered and lower dividers meet', () {
    final source = File('lib/features/shared/today_page.dart').readAsStringSync();
    final card = source.substring(source.indexOf('class _TodayResultCard'));
    expect(card, contains('height: 190,\n                          child: Center('));
    expect(card, contains('height: 58,\n                      color: AppDesign.divider,'));
    expect(card, contains('Divider(height: 1, thickness: 1, color: AppDesign.divider)'));
  });
}
