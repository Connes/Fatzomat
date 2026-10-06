import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:food_app_mvp/features/foods/food_item_image.dart';
import 'package:food_app_mvp/features/home/home_page.dart';

void main() {
  testWidgets('Lounge zeigt Willkommen zentriert ohne Ausrufezeichen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pump();

    expect(find.text('Willkommen'), findsOneWidget);
    expect(find.text('Willkommen!'), findsNothing);
    final text = tester.widget<Text>(find.text('Willkommen'));
    expect(text.textAlign, TextAlign.center);
  });

  testWidgets('Lebensmittelbild ersetzt das alte Restaurant-Icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FoodItemImage(foodName: 'Tomate'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(FoodItemImage), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
