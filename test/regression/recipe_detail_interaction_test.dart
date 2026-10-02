import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Rezeptansicht koppelt Kochen und Zubereitung an den heutigen Plan', () {
    final source = File('lib/features/recipes/recipe_detail_page.dart').readAsStringSync();
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(source, contains('bool get canWorkOnPreparation => personalTodaySelected;'));
    expect(source, contains('initiallyExpanded: ingredientsExpanded'));
    expect(source, contains('initiallyExpanded: preparationExpanded'));
    expect(source, contains('if (!canWorkOnPreparation) return false;'));
    expect(source, contains('return index == completedSteps.length;'));
    expect(source, contains('if (done) return index == completedSteps.length - 1;'));
    expect(source, contains('onTap: working || markingCooked || !enabled ? null : () => toggleStep(i)'));
    expect(source, contains("Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const TodayPage()), (route) => route.isFirst)"));
    expect(source, isNot(contains("title: 'Portionen'")));
    expect(source, isNot(contains('Schritten erledigt')));
    expect(today, contains("status == 'cooked'"));
    expect(source, contains("title: const Text('Zutaten'"));
    expect(source, contains("title: const Text('Zubereitung'"));
  });
}
