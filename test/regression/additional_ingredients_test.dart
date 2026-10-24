import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_app_mvp/data/repositories/food_repository.dart';
import 'package:food_app_mvp/data/models/food.dart';
import 'package:food_app_mvp/features/recipes/additional_ingredients_page.dart';
import '../test_shared_preferences.dart';

void main() {
  initTestSharedPreferences();

  testWidgets('V92 zeigt die verfügbaren Zutaten-Kategorien ohne Favoriten-Karte', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdditionalIngredientsPage(repository: _FakeFoodRepository()),
      ),
    );

    expect(find.text('Beilagen'), findsOneWidget);
    expect(find.text('Gemüse'), findsOneWidget);
    expect(find.text('Sonstiges'), findsOneWidget);
    expect(find.text('Favoriten'), findsNothing);
    expect(find.text('Was möchtet ihr hinzufügen?'), findsNothing);
    expect(find.text('Wählt Beilage, Gemüse oder eure Favoriten.'), findsNothing);
    expect(find.text('Hauptauswahl:'), findsNothing);
  });

  testWidgets('Hauptzutat wird auf der Seite Weitere Zutaten nicht angezeigt', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdditionalIngredientsPage(
          mainChoice: 'Rind',
          repository: _FakeFoodRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Hauptauswahl'), findsNothing);
    expect(find.text('Rind'), findsNothing);
    expect(find.text('Beilagen'), findsOneWidget);
    expect(find.text('Gemüse'), findsOneWidget);
  });

  testWidgets('Ausgewählte Zutaten werden namentlich statt nur als Anzahl angezeigt', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdditionalIngredientsPage(
          mainChoice: 'Huhn',
          initialSelectedFoodIds: const {'rice', 'broccoli', 'potato'},
          repository: _FakeFoodRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ausgewählte Zutaten (3)'), findsOneWidget);
    expect(find.text('• Reis'), findsOneWidget);
    expect(find.text('• Brokkoli'), findsOneWidget);
    expect(find.text('• Kartoffel'), findsOneWidget);
    expect(find.text('3 Zutaten ausgewählt'), findsNothing);
  });

  testWidgets('V92 Kategorieauswahl zeigt keinen unboxed Untertitel und nutzt extendBody', (tester) async {
    await _openCategory(tester, 'Beilagen');

    expect(find.text('Reis, Nudeln oder Kartoffeln'), findsNothing);
    expect(find.text('Beilagen auswählen'), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.extendBody, isTrue);
  });

  testWidgets('Beilagen umfassen die passenden Lebensmittel aus dem Katalog', (tester) async {
    await _openCategory(tester, 'Beilagen');

    expect(find.text('Reis'), findsOneWidget);
    expect(find.text('Nudeln'), findsOneWidget);
    expect(find.text('Kartoffel'), findsOneWidget);
    expect(find.text('Süßkartoffel'), findsOneWidget);
    expect(find.text('Haferflocken'), findsNothing);
    expect(find.text('Brot'), findsOneWidget);
    expect(find.text('Couscous'), findsOneWidget);
    expect(find.text('Quinoa'), findsOneWidget);
    expect(find.text('Kichererbsen'), findsOneWidget);
    expect(find.text('🍚'), findsNothing);
    expect(find.text('🍞'), findsNothing);
  });

  testWidgets('Beilagen werden in einer gemeinsamen Karte mit feinen Trennlinien angezeigt', (tester) async {
    await _openCategory(tester, 'Beilagen');

    final listView = find.byType(ListView).last;
    final card = find.ancestor(of: listView, matching: find.byType(Material)).first;
    expect(find.descendant(of: card, matching: find.byType(Divider)), findsNWidgets(7));

    final cardPadding = tester.widget<Padding>(
      find.ancestor(of: card, matching: find.byType(Padding)).first,
    );
    expect(cardPadding.padding, const EdgeInsets.fromLTRB(20, 16, 20, 8));
  });

  testWidgets('Beilagen und Gemüse zeigen Lebensmittel ohne Emojis und linksbündig', (tester) async {
    await _openCategory(tester, 'Gemüse');

    expect(find.text('Brokkoli'), findsOneWidget);
    expect(find.text('🥦'), findsNothing);
    final name = tester.widget<Text>(find.text('Brokkoli'));
    expect(name.textAlign, isNot(TextAlign.center));
    final row = tester.widget<Row>(
      find.ancestor(of: find.text('Brokkoli'), matching: find.byType(Row)).first,
    );
    expect(row.children.first, isA<Expanded>());
  });

  testWidgets('V92 Gemüse schließt Kartoffeln aus', (tester) async {
    await _openCategory(tester, 'Gemüse');

    expect(find.text('Brokkoli'), findsOneWidget);
    expect(find.text('Zucchini'), findsOneWidget);
    expect(find.text('Kartoffel'), findsNothing);
  });

  testWidgets('Sonstiges enthält übrige Lebensmittel, aber keine Gemüse- oder Beilagen-Einträge', (tester) async {
    await _openCategory(tester, 'Sonstiges');
    expect(find.text('Haferflocken'), findsOneWidget);
    expect(find.text('Paprikapulver'), findsOneWidget);
    expect(find.text('Brokkoli'), findsNothing);
    expect(find.text('Reis'), findsNothing);
    expect(find.text('Süßkartoffel'), findsNothing);
  });

  testWidgets('V92 Favoriten werden intern weiter korrekt gefiltert', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IngredientCategoryPage(
          category: IngredientCategory.favorites,
          repository: _FakeFoodRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Brokkoli'), findsOneWidget);
    expect(find.text('Reis'), findsNothing);
    expect(find.text('Karotte'), findsNothing);
  });

  testWidgets('V92 Auswahl bleibt beim Kategorie-Wechsel erhalten', (tester) async {
    await _openCategory(tester, 'Beilagen');
    await tester.tap(find.text('Reis'));
    await tester.pump();
    await tester.tap(find.text('Auswahl übernehmen (1)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gemüse'));
    await tester.pumpAndSettle();

    expect(find.text('Brokkoli'), findsOneWidget);
    expect(find.bySemanticsLabel('Reis'), findsNothing);
  });

  testWidgets('V92 Auswahl übernehmen gibt ausgewählte Food-ID zurück', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const SizedBox.shrink(),
      ),
    );

    final resultFuture = navigatorKey.currentState!.push<Set<String>>(
      MaterialPageRoute(
        builder: (_) => IngredientCategoryPage(
          category: IngredientCategory.side,
          repository: _FakeFoodRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reis'));
    await tester.pump();
    await tester.tap(find.text('Auswahl übernehmen (1)'));
    await tester.pumpAndSettle();

    expect(await resultFuture, {'rice'});
  });
}

Future<void> _openCategory(WidgetTester tester, String label) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AdditionalIngredientsPage(repository: _FakeFoodRepository()),
    ),
  );
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

class _FakeFoodRepository extends FoodRepository {
  @override
  Future<List<Food>> foods() async => [
        const Food(id: 'rice', name: 'Reis', category: 'Getreide', searchTerms: [], aliases: [], defaultUnit: 'Stück', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
        const Food(id: 'pasta', name: 'Nudeln', category: 'Pasta', searchTerms: [], aliases: [], defaultUnit: 'Stück', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
        const Food(id: 'potato', name: 'Kartoffel', category: 'Gemüse', searchTerms: [], aliases: [], defaultUnit: 'Stück', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
        const Food(id: 'oats', name: 'Haferflocken', category: 'Getreide', searchTerms: [], aliases: [], defaultUnit: 'Stück', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
        const Food(id: 'bread', name: 'Brot', category: 'Getreide & Beilagen', searchTerms: [], aliases: [], defaultUnit: 'Stück', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
        const Food(id: 'couscous', name: 'Couscous', category: 'Getreide & Beilagen', searchTerms: [], aliases: [], defaultUnit: 'g', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
        const Food(id: 'quinoa', name: 'Quinoa', category: 'Getreide & Beilagen', searchTerms: [], aliases: [], defaultUnit: 'g', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
        const Food(id: 'chickpeas', name: 'Kichererbsen', category: 'Hülsenfrüchte', searchTerms: [], aliases: [], defaultUnit: 'g', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
        const Food(id: 'broccoli', name: 'Brokkoli', category: 'Gemüse', searchTerms: [], aliases: [], defaultUnit: 'Stück', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
        const Food(id: 'zucchini', name: 'Zucchini', category: 'Gemüse', searchTerms: [], aliases: [], defaultUnit: 'Stück', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
        const Food(id: 'carrot', name: 'Karotte', category: 'Gemüse', searchTerms: [], aliases: [], defaultUnit: 'Stück', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
        const Food(id: 'sweet-potato', name: 'Süßkartoffel', category: 'Gemüse', searchTerms: [], aliases: [], defaultUnit: 'Stück', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
        const Food(id: 'paprika-powder', name: 'Paprikapulver', category: 'Gewürze', searchTerms: [], aliases: [], defaultUnit: 'g', dietaryType: 'vegan', allergens: [], proteinType: 'plant'),
      ];

  @override
  Future<Map<String, String>> preferences() async => const {
        'broccoli': 'like',
      };
}
