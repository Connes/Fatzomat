import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/core/app_design.dart';
import 'package:food_app_mvp/features/recipes/saved_recipes_page.dart';

void main() {
  testWidgets('Meine Rezepte zeigt den Empty State als klar erkennbare Box', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppDesign.theme(),
        home: const SavedRecipesEmptyState(),
      ),
    );

    final emptyState = find.byKey(const ValueKey<String>('my_recipes_empty_state'));
    expect(emptyState, findsOneWidget);
    expect(find.text('Meine Rezepte'), findsNothing);
    expect(find.text('Noch keine Rezepte in deiner Sammlung'), findsOneWidget);
    expect(
      find.text('Finde ein Rezept oder füge ein Lieblingsrezept hinzu.'),
      findsOneWidget,
    );

    final surface = find.descendant(
      of: emptyState,
      matching: find.byType(Container),
    );
    expect(surface, findsOneWidget);

    final container = tester.widget<Container>(surface);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppDesign.surface);
    expect(decoration.border, isNotNull);
    expect(decoration.borderRadius, BorderRadius.circular(22));
  });

  test('Meine Rezepte zeigt den Empty State nur bei leerer Rezeptliste', () {
    final source = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();

    expect(
      source,
      contains('if (visibleRecipes.isEmpty)'),
    );
    expect(
      source,
      contains('return recipes.isEmpty'),
    );
    expect(
      source,
      contains("'Kein passendes Rezept gefunden.'"),
    );
    expect(source, contains("title: const Text('Meine Rezepte')"));
    expect(source, contains('if (recipes.isNotEmpty)'));
    expect(source, contains("hintText: 'Rezepte suchen'"));
  });
}
