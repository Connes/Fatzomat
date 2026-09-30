import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_app_mvp/data/repositories/food_repository.dart';
import 'package:food_app_mvp/core/app_design.dart';
import 'package:food_app_mvp/core/food_mode.dart';
import 'package:food_app_mvp/core/services/food_choice_asset_service.dart';
import 'package:food_app_mvp/data/models/food.dart';
import 'package:food_app_mvp/features/food_modes/cook_next_step_page.dart';
import 'package:food_app_mvp/features/recipes/additional_ingredients_page.dart';
import 'package:food_app_mvp/features/recipes/saved_recipes_page.dart';
import '../test_shared_preferences.dart';

void main() {
  initTestSharedPreferences();

  testWidgets('V94 zeigt die Hauptauswahl in Meine Wahl ohne redundante Überschrift', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CookNextStepPage(
          mainChoice: 'Schwein',
          repository: _FakeFoodRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Schwein'), findsOneWidget);
    expect(find.text('Meine Wahl'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                FoodChoiceAssetService.assetFor(FoodMode.cook, 'Schwein'),
      ),
      findsOneWidget,
    );
    expect(find.text('Weitere Zutaten hinzufügen'), findsOneWidget);
    final actionCard = tester.widget<Card>(
      find.ancestor(
        of: find.text('Weitere Zutaten hinzufügen'),
        matching: find.byType(Card),
      ).first,
    );
    expect(actionCard.color, AppDesign.primarySoft);
  });

  testWidgets('V94 verwendet das passende bestehende Bild für jede Hauptauswahl', (tester) async {
    for (final choice in ['Rind', 'Schwein', 'Huhn', 'Fisch', 'Vegetarisch']) {
      await tester.pumpWidget(
        MaterialApp(
          home: CookNextStepPage(
            mainChoice: choice,
            repository: _FakeFoodRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final asset = FoodChoiceAssetService.assetFor(FoodMode.cook, choice);
      expect(asset, isNotNull);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == asset,
        ),
        findsOneWidget,
        reason: 'Passendes Auswahlbild fehlt: $choice',
      );
    }
  });

  testWidgets('V94 zeigt alle Hauptauswahlen nur innerhalb von Meine Wahl', (tester) async {
    for (final choice in ['Rind', 'Schwein', 'Huhn', 'Fisch', 'Vegetarisch']) {
      await tester.pumpWidget(
        MaterialApp(
          home: CookNextStepPage(
            mainChoice: choice,
            repository: _FakeFoodRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(choice), findsOneWidget, reason: 'Hauptauswahl darf nur innerhalb von Meine Wahl erscheinen: $choice');
      expect(find.text('Meine Wahl'), findsOneWidget);
      expect(find.text('Weitere Zutaten hinzufügen'), findsOneWidget);
    }
  });

  testWidgets('V94 öffnet über Weitere Zutaten den bestehenden V92-Zutatenfluss', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CookNextStepPage(
          mainChoice: 'Huhn',
          repository: _FakeFoodRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weitere Zutaten hinzufügen'));
    await tester.pumpAndSettle();

    expect(find.byType(AdditionalIngredientsPage), findsOneWidget);
    expect(find.textContaining('Huhn'), findsWidgets);
    expect(find.text('Beilage'), findsOneWidget);
    expect(find.text('Gemüse'), findsOneWidget);
    expect(find.text('Favoriten'), findsNothing);
  });

  testWidgets('V94 übernimmt hinzugefügte Zutaten zurück in Meine Wahl', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CookNextStepPage(
          mainChoice: 'Schwein',
          repository: _FakeFoodRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weitere Zutaten hinzufügen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beilage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reis'));
    await tester.pump();
    await tester.tap(find.text('Auswahl übernehmen (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auswahl übernehmen (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Meine Wahl'), findsOneWidget);
    expect(find.text('Schwein'), findsOneWidget);
    expect(find.text('Reis'), findsOneWidget);
    expect(find.text('Weitere Zutaten hinzufügen (1 ausgewählt)'), findsOneWidget);
  });

  testWidgets('V94 öffnet die gespeicherte Rezeptsuche mit der Auswahl', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CookNextStepPage(
          mainChoice: 'Rind',
          repository: _FakeFoodRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weitere Zutaten hinzufügen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beilage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reis'));
    await tester.pump();
    await tester.tap(find.text('Auswahl übernehmen (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auswahl übernehmen (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Rezepte finden'), findsNothing);
    final summaryList = find.byType(ListView);
    expect(summaryList, findsOneWidget);
    await tester.drag(summaryList, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Neue Rezepte suchen'), findsOneWidget);
    expect(find.text('Aus meinen Rezepten suchen'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cook-summary-saved-recipes')));
    await tester.pumpAndSettle();

    expect(find.byType(
      SavedRecipesPage,
    ), findsOneWidget);
  });
  testWidgets('V94 trennt neue und gespeicherte Rezeptsuche', (tester) async {
    final observer = _RecordingNavigatorObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: CookNextStepPage(
          mainChoice: 'Huhn',
          repository: _FakeFoodRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Rezepte finden'), findsNothing);
    expect(find.byKey(const Key('cook-summary-new-recipes')), findsOneWidget);
    expect(find.byKey(const Key('cook-summary-saved-recipes')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('cook-summary-saved-recipes')),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('cook-summary-new-recipes')));
    await tester.pump();

    expect(observer.lastPushedRouteName, '/cook/new-recipes');
  });

}


class _RecordingNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? lastPushedRoute;

  String? get lastPushedRouteName => lastPushedRoute?.settings.name;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushedRoute = route;
    super.didPush(route, previousRoute);
  }
}

class _FakeFoodRepository extends FoodRepository {
  @override
  Future<List<Food>> foods() async => [
        const Food(id: 'rice', name: 'Reis', category: 'Getreide', searchTerms: [], aliases: [], defaultUnit: 'Stück', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
        const Food(id: 'pasta', name: 'Nudeln', category: 'Pasta', searchTerms: [], aliases: [], defaultUnit: 'Stück', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
        const Food(id: 'potato', name: 'Kartoffel', category: 'Gemüse', searchTerms: [], aliases: [], defaultUnit: 'Stück', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
        const Food(id: 'broccoli', name: 'Brokkoli', category: 'Gemüse', searchTerms: [], aliases: [], defaultUnit: 'Stück', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
      ];

  @override
  Future<Map<String, String>> preferences() async => const {};
}

