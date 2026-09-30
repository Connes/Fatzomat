import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/core/app_design.dart';
import 'package:food_app_mvp/features/recipes/add_recipe_page.dart';
import 'package:food_app_mvp/data/models/recipe.dart';

void main() {
  testWidgets('Rezept hinzufügen verwendet den Rezepte-Hintergrund und zeigt die drei neuen Importwege', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppDesign.theme(),
        home: const AddRecipePage(),
      ),
    );
    await tester.pump();

    expect(find.text('Rezept hinzufügen'), findsOneWidget);
    expect(find.text('Mit ChatGPT erstellen'), findsOneWidget);
    expect(find.text('Rezept aus Foto erstellen'), findsOneWidget);
    expect(find.text('Rezeptdatei importieren'), findsOneWidget);

    final background = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/together/clean/background/recipes_background.png',
    );
    expect(background, findsOneWidget);

    expect(
      find.text(
        'Schmackofatz verarbeitet beim Dateiimport nur das definierte together_recipe-Format. '
        'Es ist keine KI und keine OpenAI-API erforderlich.',
      ),
      findsNothing,
    );
  });

  test('Rezept hinzufügen bietet nur gemeinsame Importwege an', () {
    final source = File('lib/features/recipes/add_recipe_page.dart').readAsStringSync();

    expect(source, isNot(contains("title: 'Manuell erstellen'")));
    expect(source, contains("title: 'Mit ChatGPT erstellen'"));
    expect(source, contains("title: 'Rezept aus Foto erstellen'"));
    expect(source, contains("title: 'Rezeptdatei importieren'"));
    expect(source, contains('_importFile(context)'));
    expect(source, contains('const ChatGptRecipeSetupPage()'));
    expect(source, contains('const PhotoRecipeChatGptPage()'));
    expect(source, isNot(contains('Schmackofatz verarbeitet beim Dateiimport')));
  });

  testWidgets('Rezept bearbeiten verwendet die bestehende responsive Editor-Struktur', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppDesign.theme(),
        home: ManualRecipePage(
          initialRecipe: const Recipe(
            id: 'test-recipe',
            name: 'Testrezept',
            description: 'Test',
            servings: 2,
            prepTimeMinutes: 10,
            cookTimeMinutes: 20,
            difficulty: 'Einfach',
            instructions: ['Schritt 1'],
            ingredients: [RecipeIngredient(name: 'Tomate', quantity: 2, unit: 'Stück')],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Rezept bearbeiten'), findsOneWidget);
    expect(find.text('Änderungen speichern'), findsOneWidget);

    // The ingredient and preparation sections live below the initial viewport
    // of the lazy ListView. Scroll before asserting their widgets exist.
    final listView = find.byType(ListView);
    expect(listView, findsOneWidget);
    await tester.drag(listView, const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Zutaten'), findsOneWidget);
    expect(find.text('Zubereitung'), findsOneWidget);
    expect(find.text('Zutat hinzufügen'), findsOneWidget);
    expect(find.text('Schritt hinzufügen'), findsOneWidget);

    // The manual form deliberately extends its transparent action area over the
    // shared background so the old black strip cannot return.
    final manualSource = File('lib/features/recipes/add_recipe_page.dart').readAsStringSync();
    expect(manualSource, contains('extendBody: true'));
    expect(manualSource, contains("backgroundColor: AppDesign.primary"));

    // The ingredient section is below several fields in a lazy ListView.
    // Scroll the list directly instead of using scrollUntilVisible on a target
    // that may not have been built yet.
    final ingredientNameField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == 'Zutat',
    );
    expect(ingredientNameField, findsOneWidget);
    expect(find.text('Menge'), findsOneWidget);
    expect(find.text('Einheit'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);

    final quantityField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == 'Menge',
    );
    final unitField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == 'Einheit',
    );
    expect(quantityField, findsOneWidget);
    expect(unitField, findsOneWidget);
  });

test('Manuelle Rezeptseite nutzt bestehende Speicherlogik und responsive Zutatenstruktur', () {
  final source = File('lib/features/recipes/add_recipe_page.dart').readAsStringSync();

  expect(source, contains('await RecipeRepository().saveRecipeModel(recipe);'));
  expect(source, contains("label: Text(saving ? 'Speichern …' : (editing ? 'Änderungen speichern' : 'Rezept speichern'))"));
  expect(source, contains("labelText: 'Menge'"));
  expect(source, contains("labelText: 'Einheit'"));
  expect(source, contains('controller: draft.amount'));
  expect(source, contains('controller: draft.unit'));
  expect(source, isNot(contains('DropdownButtonFormField<String>')));
  expect(source, contains('Expanded('));
});

  test('ChatGPT-Rezeptseite nutzt die vorhandenen Hauptauswahl-PNGs und den einheitlichen Button-Stil', () {
    final source = File('lib/features/recipes/add_recipe_page.dart').readAsStringSync();
    final assetSource = File('lib/core/services/food_choice_asset_service.dart').readAsStringSync();

    expect(source, contains('extendBody: true'));
    expect(source, contains('FoodChoiceAssetService.assetFor(FoodMode.cook, choice)'));
    expect(assetSource, contains("'Rind': 'assets/food_choices/cooking/rind.png'"));
    expect(assetSource, contains("'Schwein': 'assets/food_choices/cooking/schwein.png'"));
    expect(assetSource, contains("'Huhn': 'assets/food_choices/cooking/huhn.png'"));
    expect(assetSource, contains("'Fisch': 'assets/food_choices/cooking/fisch.png'"));
    expect(assetSource, contains("'Vegetarisch': 'assets/food_choices/cooking/vegetarisch.png'"));
    expect(source, isNot(contains("Text('1. Hauptauswahl'")));
    expect(source, isNot(contains("Text('2. Zutaten auswählen'")));
    expect(source, isNot(contains("Text('3. Prompt kopieren und ChatGPT öffnen'")));
    expect(source, isNot(contains('Die Auswahl entspricht dem Zutaten-Flow aus „Wir kochen“.')));
    expect(source, isNot(contains('Der Prompt landet automatisch in der Zwischenablage.')));
    expect(source, contains("label: const Text('Erstellte JSON-Datei importieren')"));
    expect(source, contains('onPressed: _importRecipeFile'));
    expect(source, contains('mainAxisSpacing: 16'));
    expect(source, contains('crossAxisSpacing: 16'));
  });

test('Import-Vorschau bietet Bearbeiten vor dem Speichern an', () {
  final source = File('lib/features/recipes/add_recipe_page.dart').readAsStringSync();
  expect(source, contains("label: const Text('Rezept bearbeiten')"));
  expect(source, contains('returnRecipeOnly: true'));
  expect(source, isNot(contains('final missingUnits = _recipe.ingredients')));
});

}
