import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Rezeptansicht führt nach dem Kochen zu Heute und vermeidet doppelte Fortschrittsanzeige', () {
    final recipe = File('lib/features/recipes/recipe_detail_page.dart').readAsStringSync();
    final today = File('lib/features/shared/today_page.dart').readAsStringSync();

    expect(recipe, isNot(contains("SectionHeader(title: 'Portionen'")));
    expect(recipe, isNot(contains("Die Mengen passen sich automatisch an.")));
    expect(recipe, isNot(contains(r"Schritten erledigt")));
    expect(recipe, contains("personalToday.updateStatus(plan.id, 'cooked')"));
    expect(recipe, contains('Navigator.pushReplacement('));
    expect(recipe, contains('MaterialPageRoute(builder: (_) => const TodayPage())'));
    expect(recipe, contains('onNavigateToToday'));
    expect(recipe, contains('widget.onNavigateToToday!();'));
    expect(recipe, contains('Navigator.pop(context);'));
    expect(today, contains("onOpenRecipe: plan!.isRecipe && plan!.status != 'cooked'"));
    expect(today, contains('final VoidCallback? onOpenRecipe;'));

    expect(today, contains("plan.status == 'cooked'"));
    expect(today, contains("Icons.check_circle_rounded"));
    expect(today, contains("Text('Gekocht'"));
    expect(today, contains("Für heute ist alles erledigt."));
    expect(today, contains("Deine Entscheidung ist abgeschlossen."));
    expect(today, contains("plan!.status == 'cooked' || plan!.isShared"));
  });
}
