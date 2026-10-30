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
    expect(recipe, contains('else if (widget.planDate != null)'));
    expect(recipe, contains('Navigator.pushReplacement('));
    expect(recipe, contains('onNavigateToToday'));
    expect(recipe, contains('final navigateToToday = widget.onNavigateToToday!;'));
    expect(recipe, contains('Navigator.pop(context);'));
    expect(recipe, contains('navigateToToday();'));
    expect(
      recipe.indexOf('Navigator.pop(context);'),
      lessThan(recipe.indexOf('navigateToToday();')),
    );
    expect(recipe, isNot(contains('onPressed: working ? null : selectPersonalToday')));
    expect(recipe, isNot(contains("'Plan wird gespeichert …'")));
    expect(recipe, isNot(contains("'Für heute festlegen'")));
    expect(recipe, isNot(contains("'Für diesen Tag festlegen'")));
    expect(recipe, contains('final bool canMarkCooked'));
    expect(recipe, contains('if (!widget.viewingTodaySelection || !personalTodaySelected || working) return;'));
    expect(recipe, contains("label: const Text('Als gekocht abschließen')"));
    expect(recipe, contains("widget.viewingTodaySelection &&\n              personalTodaySelected &&\n              _isPlanDateToday &&\n              steps.isNotEmpty &&\n              completedSteps.length == steps.length"));
    expect(recipe, contains("completedSteps.length == steps.length"));
    expect(recipe, contains("if (widget.viewingTodaySelection &&\n              widget.canMarkCooked"));
    expect(recipe, contains('FilledButton.icon('));
    expect(recipe, isNot(contains('bottomNavigationBar: widget.viewingTodaySelection')));
    expect(recipe, isNot(contains("if (personalTodaySelected || widget.viewingTodaySelection) ...[")));
    expect(recipe, contains("final bool viewingTodaySelection"));
    expect(recipe, contains("actions: !widget.showManagementActions ? null : ["));
    expect(recipe, isNot(contains("'Für heute ausgewählt'")));
    expect(recipe, isNot(contains("'Für diesen Tag ausgewählt'")));
    expect(recipe, isNot(contains("'Für heute ausgewählt'")));
    expect(today, contains("onOpenRecipe: plan!.isRecipe && plan!.status != 'cooked'"));
    expect(today, contains('final VoidCallback? onOpenRecipe;'));

    expect(today, contains("plan.status == 'cooked'"));
    expect(today, contains("Icons.check_circle_rounded"));
    expect(today, contains('_TodayDecisionCardActions('));
    expect(today, contains("if (isCompleted)"));
    expect(today, contains("Für heute ist alles erledigt."));
    expect(today, contains("Deine Entscheidung ist abgeschlossen."));
    expect(today, contains("plan!.status == 'cooked' || plan!.isShared"));
    final shoppingEntry = File('lib/features/shared/shopping_list_page.dart').readAsStringSync();
    expect(shoppingEntry, contains('MultiDayShoppingListPage'));
    expect(shoppingEntry, isNot(contains('personalPlanId')));
  });
}
