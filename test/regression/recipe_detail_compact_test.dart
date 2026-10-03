import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Rezeptansicht zeigt Zutaten und Zubereitung kompakt und schaltet Schritte nur der Reihe nach', () {
    final source = File('lib/features/recipes/recipe_detail_page.dart').readAsStringSync();

    expect(source, contains('bool ingredientsExpanded = false;'));
    expect(source, contains('bool preparationExpanded = false;'));
    expect(source, contains("initiallyExpanded: false"));
    expect(source, contains("title: const Text('Zutaten'"));
    expect(source, contains("title: const Text('Zubereitung'"));
    expect(source, contains('final nextStep = i == completedSteps.length;'));
    expect(source, contains('final canToggle = personalTodaySelected &&'));
    expect(source, contains('(done && i == completedSteps.length - 1)'));
    expect(source, contains('(personalTodaySelected && !done && nextStep)'));
    expect(source, isNot(contains('Icons.soup_kitchen_rounded')));
    expect(source, isNot(contains("Schritten erledigt")));
  });
}
