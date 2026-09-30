import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_app_mvp/core/food_mode.dart';
import 'package:food_app_mvp/core/widgets/together_background.dart';
import 'package:food_app_mvp/core/widgets/together_scaffold.dart';
import 'package:food_app_mvp/features/food_modes/food_mode_page.dart';

void main() {
  testWidgets('V95 TogetherAppBar zentriert den Seitentitel', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TogetherScaffold(
          backgroundType: TogetherBackgroundType.recipes,
          appBar: TogetherAppBar(title: Text('Wir kochen')),
          body: SizedBox.shrink(),
        ),
      ),
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.centerTitle, isTrue);
    expect(find.text('Wir kochen'), findsOneWidget);
  });

  testWidgets('V95 direkte Startseiten-Unterseiten tragen ihre Seitennamen',
      (tester) async {
    for (final entry in const <FoodMode, String>{
      FoodMode.cook: 'Wir kochen',
      FoodMode.order: 'Wir bestellen',
      FoodMode.dineOut: 'Wir gehen essen',
    }.entries) {
      await tester.pumpWidget(
        MaterialApp(home: FoodModePage(mode: entry.key)),
      );
      await tester.pump();

      expect(find.text(entry.value), findsOneWidget);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, isTrue);
    }
  });
}
