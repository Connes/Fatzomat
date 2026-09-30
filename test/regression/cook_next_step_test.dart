import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_app_mvp/core/food_mode.dart';
import 'package:food_app_mvp/features/food_modes/cook_next_step_page.dart';
import 'package:food_app_mvp/features/food_modes/food_mode_page.dart';
import 'package:food_app_mvp/features/recipes/add_recipe_page.dart';

void main() {
  testWidgets('V94 öffnet nach Wir-kochen-Auswahl die persönliche Zusammenfassung', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FoodModePage(mode: FoodMode.cook)));
    final huhn = find.text('Huhn');
    expect(huhn, findsOneWidget);
    await tester.ensureVisible(huhn);
    await tester.tap(huhn);
    await tester.pumpAndSettle();

    expect(find.byType(CookNextStepPage), findsOneWidget);
    expect(find.text('Huhn'), findsOneWidget);
    expect(find.text('Meine Wahl'), findsOneWidget);
    expect(find.text('Weitere Zutaten hinzufügen'), findsOneWidget);
  });

  testWidgets('V89/V94 direkte Generierungsseite bleibt vorhanden', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CookRecipeGenerationPage(mainChoice: 'Huhn')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(CookRecipeGenerationPage, skipOffstage: false), findsOneWidget);
  });
  testWidgets('Wir kochen verwendet den externen ChatGPT-Rezeptworkflow', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CookRecipeGenerationPage(mainChoice: 'Huhn'),
      ),
    );
    await tester.pump();

    expect(find.byType(CookRecipeGenerationPage, skipOffstage: false), findsOneWidget);
    expect(find.byType(ChatGptRecipeSetupPage), findsOneWidget);
  });

}
