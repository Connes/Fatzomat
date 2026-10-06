import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_app_mvp/core/app_design.dart';
import 'package:food_app_mvp/core/food_mode.dart';
import 'package:food_app_mvp/core/services/food_choice_asset_service.dart';
import 'package:food_app_mvp/features/food_modes/food_mode_page.dart';

Finder _assetImageFinder(String assetName) => find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == assetName,
    );

Finder _fullBleedSelectionImageFinder() => find.byWidgetPredicate(
      (widget) {
        if (widget is! Image || widget.fit != BoxFit.cover || widget.image is! AssetImage) {
          return false;
        }
        final asset = (widget.image as AssetImage).assetName;
        return asset.startsWith('assets/food_choices/') ||
            asset == 'assets/together/clean/icons/icon_surprise.png';
      },
    );

void main() {
  test('Food-Choice-Asset-Mapping deckt alle bildgestützten Auswahlmöglichkeiten ab', () {
    expect(
      FoodChoiceAssetService.choicesFor(FoodMode.cook).keys,
      containsAll(['Rind', 'Schwein', 'Huhn', 'Fisch', 'Vegetarisch']),
    );
    expect(
      FoodChoiceAssetService.choicesFor(FoodMode.order).keys,
      containsAll(['Pizza', 'Burger', 'Asiatisch', 'Döner', 'Sushi', 'Indisch']),
    );
    expect(
      FoodChoiceAssetService.choicesFor(FoodMode.dineOut).keys,
      containsAll([
        'Italienisch',
        'Steak',
        'Sushi',
        'Burger',
        'Mexikanisch',
        'Vegetarisch',
      ]),
    );
  });

  test('Food-Choice-Assets sind im Flutter-Asset-Bundle verfügbar', () async {
    final assets = <String>{
      for (final mode in FoodMode.values)
        ...FoodChoiceAssetService.choicesFor(mode).values,
    };

    for (final asset in assets) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }

    final surprise = FoodChoiceAssetService.assetFor(
      FoodMode.cook,
      'Überrasch mich',
    )!;
    final surpriseData = await rootBundle.load(surprise);
    expect(surpriseData.lengthInBytes, greaterThan(0), reason: surprise);
  });

  Future<void> pumpMode(
    WidgetTester tester,
    FoodMode mode,
    List<String> labels, {
    List<String>? assetLabels,
  }) async {
    final imageLabels = assetLabels ?? labels;
    await tester.pumpWidget(
      MaterialApp(home: FoodModePage(mode: mode)),
    );
    await tester.pumpAndSettle();

    final compactMode = mode == FoodMode.cook || mode == FoodMode.order;
    expect(
      find.byKey(const ValueKey<String>('food_mode_choice_group')),
      compactMode ? findsNothing : findsOneWidget,
    );
    expect(find.byType(AppSurface), compactMode ? findsNothing : findsOneWidget);
    expect(find.byType(SingleChildScrollView), compactMode ? findsNothing : findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);

    for (final label in labels) {
      expect(find.text(label), findsOneWidget, reason: 'Auswahl fehlt: $label');
    }

    final expectedInteractiveCards = labels.length + (mode == FoodMode.order ? 1 : 0);
    expect(find.byType(InkWell), findsNWidgets(expectedInteractiveCards));
    if (mode == FoodMode.order) {
      expect(find.text('Lieferdienste'), findsOneWidget);
    }
    expect(_fullBleedSelectionImageFinder(), findsNWidgets(imageLabels.length));
    if (compactMode) {
      expect(find.byType(Scrollable), findsOneWidget);
    }

    for (final label in imageLabels) {
      final asset = FoodChoiceAssetService.assetFor(mode, label)!;
      expect(_assetImageFinder(asset), findsOneWidget, reason: 'Asset fehlt: $asset');
    }
  }

  testWidgets('Wir kochen zeigt fünf Kategorien ohne Sammelbox und mit ausgeglichenem Abstand',
      (tester) async {
    await pumpMode(tester, FoodMode.cook, const [
      'Rind',
      'Schwein',
      'Huhn',
      'Fisch',
      'Vegetarisch',
    ]);
  });

  testWidgets('Wir bestellen hat eine gemeinsame Box, vollflächige Bilder und alle Auswahltexte',
      (tester) async {
    await pumpMode(tester, FoodMode.order, const [
      'Pizza',
      'Burger',
      'Asiatisch',
      'Döner',
      'Sushi',
      'Indisch',
    ]);
  });

  testWidgets('Wir gehen essen hat eine gemeinsame Box und alle Auswahltexte',
      (tester) async {
    await pumpMode(
      tester,
      FoodMode.dineOut,
      const [
        'Italienisch',
        'Griechisch',
        'Türkisch',
        'Japanisch',
        'Chinesisch',
        'Thailändisch',
        'Vietnamesisch',
        'Koreanisch',
        'Indonesisch',
        'Malaysisch',
        'Sushi',
        'Burger',
        'Steak',
        'Mexikanisch',
        'Spanisch',
        'Libanesisch',
        'Portugiesisch',
        'Vegetarisch',
        'Vegan',
      ],
      assetLabels: const [
        'Italienisch',
        'Steak',
        'Sushi',
        'Burger',
        'Mexikanisch',
        'Vegetarisch',
      ],
    );
  });

  testWidgets('Die drei Auswahlseiten zeigen keinen Überraschungsweg', (tester) async {
    for (final mode in FoodMode.values) {
      await tester.pumpWidget(MaterialApp(home: FoodModePage(mode: mode)));
      await tester.pumpAndSettle();
      expect(find.text('Überrasch mich'), findsNothing);
    }
  });
}
