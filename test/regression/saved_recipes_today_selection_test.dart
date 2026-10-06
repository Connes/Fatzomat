import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V87 shows already-selected state instead of an active today action', () {
    final source = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();

    expect(source, contains('todayPlan?.isRecipe == true'));
    expect(source, contains('todayPlan?.recipeId == recipe.id'));
    expect(source, contains("todayPlan?.status != 'cooked'"));
    expect(source, contains("'Für heute ausgewählt'"));
    expect(source, contains("key: Key('saved-recipe-select-today-"));
    expect(source, contains("onPressed: () => selectRecipeForToday(recipe)"));
    expect(source, contains("bool get hasActiveTodayPlan => todayPlan != null && todayPlan!.status != 'cooked';"));
    expect(source, contains('if (hasActiveTodayPlan)'));
  });
}
