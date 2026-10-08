import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Rezeptansicht plant nur für Heute und delegiert die Heute-Navigation an den AppShell', () {
    final recipe = File('lib/features/recipes/recipe_detail_page.dart').readAsStringSync();
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(recipe, isNot(contains("SectionHeader(title: 'Portionen'")));
    expect(recipe, isNot(contains("Die Mengen passen sich automatisch an.")));
    expect(recipe, isNot(contains(r"Schritten erledigt")));
    expect(recipe, contains("personalToday.updateStatus(today.id, 'cooked')"));
    expect(recipe, contains('RecipeCollectionEvents.notifyChanged();'));
    expect(recipe, contains("if (widget.onNavigateToToday != null)"));
    expect(recipe, contains("Navigator.pushReplacement("));
    expect(recipe, contains("MaterialPageRoute(builder: (_) => const TodayPage())"));
    expect(recipe, contains('Navigator.pushReplacement('));
    expect(recipe, contains('onNavigateToToday'));
    expect(recipe, contains('final navigateToToday = widget.onNavigateToToday!;'));
    expect(recipe, contains('Navigator.pop(context);'));
    expect(recipe, contains('navigateToToday();'));
    expect(
      recipe.indexOf('Navigator.pop(context);'),
      lessThan(recipe.indexOf('navigateToToday();')),
    );
    expect(recipe, contains('FilledButton.icon('));
    expect(recipe, contains('onPressed: working ? null : selectPersonalToday'));
    expect(recipe, contains("label: Text("));
    expect(recipe, contains("'Für heute vorbereiten …'"));
    expect(recipe, contains("'Für heute festlegen'"));
    expect(recipe, contains('if (!personalTodaySelected)'));
    expect(recipe, contains('final bool canMarkCooked'));
    expect(recipe, contains('if (!widget.canMarkCooked || working) return;'));
    expect(recipe, contains("label: const Text('Als gekocht markieren')"));
    expect(recipe, contains("if (widget.canMarkCooked && steps.isNotEmpty && completedSteps.contains(steps.length - 1))"));
    expect(
      recipe.indexOf("completedSteps.contains(steps.length - 1)"),
      lessThan(recipe.indexOf("label: const Text('Als gekocht markieren')")),
    );
    final bottomNavigation = recipe.substring(recipe.indexOf('bottomNavigationBar:'));
    expect(bottomNavigation, isNot(contains('widget.canMarkCooked')));
    expect(recipe, contains("if (personalTodaySelected || widget.viewingTodaySelection) ...["));
    expect(recipe, contains("final bool viewingTodaySelection"));
    expect(recipe, contains("actions: widget.viewingTodaySelection ? null : ["));
    expect(recipe, contains("'Für heute ausgewählt'"));
    expect(
      recipe.indexOf("'Für heute ausgewählt'"),
      lessThan(recipe.lastIndexOf('recipe!.name')),
    );
    expect(bottomNavigation, isNot(contains("'Für heute ausgewählt'")));
    expect(today, contains("onOpenRecipe: plan!.isRecipe && plan!.status != 'cooked'"));
    expect(today, contains('final VoidCallback? onOpenRecipe;'));

    expect(today, contains("plan.status == 'cooked'"));
    expect(today, contains("Icons.check_circle_rounded"));
    expect(today, contains("Text('Gekocht'"));
    expect(today, contains("Für heute ist alles erledigt."));
    expect(today, contains("Deine Entscheidung ist abgeschlossen."));
    expect(today, contains("plan!.status == 'cooked' || plan!.isShared"));
    final shoppingEntry = File('lib/features/shared/shopping_list_page.dart').readAsStringSync();
    expect(shoppingEntry, contains("final activePersonal = personal?.status == 'cooked' || personal?.isRecipe != true ? null : personal;"));
    expect(shoppingEntry, contains('personalPlanId = activePersonal?.id;'));
  });
}
