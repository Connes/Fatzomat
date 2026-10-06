import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/food_mode.dart';
import '../../lib/core/services/food_choice_asset_service.dart';
import '../../lib/features/food_modes/food_mode_page.dart';

void main() {
  testWidgets('Wir bestellen zeigt Kategorien inklusive Schnitzel und Pasta ohne Lieferdienst-Abzweig', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FoodModePage(mode: FoodMode.order),
      ),
    );
    await tester.pump();

    for (final choice in [
      'Pizza',
      'Burger',
      'Asiatisch',
      'Döner',
      'Sushi',
      'Indisch',
      'Schnitzel',
      'Pasta',
    ]) {
      expect(find.text(choice), findsOneWidget);
    }

    expect(find.text('Lieferdienste'), findsNothing);
    expect(find.byType(DiscoveryPage), findsNothing);
  });

  test('Schnitzel und Pasta verwenden eigene Bildassets', () {
    expect(
      FoodChoiceAssetService.assetFor(FoodMode.order, 'Schnitzel'),
      'assets/food_choices/order/schnitzel.webp',
    );
    expect(
      FoodChoiceAssetService.assetFor(FoodMode.order, 'Pasta'),
      'assets/food_choices/order/pasta.webp',
    );
  });
}
