import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/features/foods/food_item_image.dart';

void main() {
  testWidgets('food illustration slot renders no image, emoji, or placeholder',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FoodItemImage(foodName: 'Apfel'),
              FoodItemImage(foodName: 'Unbekanntes Lebensmittel'),
              FoodItemImage(foodName: 'Halloumi', category: 'Milchprodukte'),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(Text), findsNothing);
    expect(find.byType(FoodItemImage), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('food illustration slot takes no layout space',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FoodItemImage(foodName: 'Karotten', size: 64),
        ),
      ),
    );

    final size = tester.getSize(find.byType(FoodItemImage));
    expect(size, Size.zero);
  });
}
