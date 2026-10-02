import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Rezeptansicht koppelt Kochen und Zubereitung an den heutigen Plan', () {
    final source = File('lib/features/recipes/recipe_detail_page.dart').readAsStringSync();

    expect(source, contains('if (personalTodaySelected) ...['));
    expect(source, contains('bool get canWorkOnPreparation => personalTodaySelected;'));
    expect(source, contains('if (!canWorkOnPreparation) return false;'));
    expect(source, contains('return index == completedSteps.length;'));
    expect(source, contains('if (done) return index == completedSteps.length - 1;'));
    expect(source, contains('onTap: working || markingCooked || !enabled ? null : () => toggleStep(i)'));
    expect(source, contains('ExpansionTile('));
    expect(source, contains("title: const Text('Zutaten'"));
    expect(source, contains("title: const Text('Zubereitung'"));
  });
}
