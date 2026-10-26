import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recipe library uses date selection instead of a Today-specific state', () {
    final source = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();

    expect(source, contains("label: const Text('Auswählen')"));
    expect(source, contains("Key('cook-search-select-recipe-"));
    expect(source, contains("'Für heute auswählen'"));
    expect(source, contains("'Für diesen Tag auswählen'"));
    expect(source, contains('onPressed: () => selectRecipeForToday(recipe)'));
    expect(source, contains('Future<DateTime?> _choosePlanDate()'));
    expect(source, contains('itemCount: 7'));
    expect(source, contains('enabled: label == null'));
    expect(source, isNot(contains('todayPlan?.isRecipe == true')));
    expect(source, isNot(contains('Für heute ausgewählt')));
    expect(source, isNot(contains('if (hasActiveTodayPlan)')));

    final cookSearchCard = source.substring(
      source.indexOf("Key('cook-search-select-recipe-") - 1800,
      source.indexOf("Key('cook-search-select-recipe-") + 900,
    );
    expect(cookSearchCard, contains('padding: const EdgeInsets.fromLTRB(14, 10, 12, 8)'));
    expect(cookSearchCard, contains('crossAxisAlignment: CrossAxisAlignment.center'));
    expect(cookSearchCard, contains('maxLines: 2'));
    expect(cookSearchCard, contains('overflow: TextOverflow.ellipsis'));
    expect(cookSearchCard, contains("label: Text("));
    expect(cookSearchCard, isNot(contains('Rezept bearbeiten')));
    expect(cookSearchCard, isNot(contains('Rezept teilen')));
    expect(cookSearchCard, isNot(contains('Rezept löschen')));
  });
}
