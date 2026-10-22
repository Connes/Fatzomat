import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/core/food_mode.dart';
import '../../lib/features/food_modes/food_mode_page.dart';
import '../../lib/features/food_modes/chatgpt_restaurant_page.dart';

const _dineOutChoices = [
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
];

void main() {
  for (final choice in _dineOutChoices) {
    testWidgets('Wir gehen essen: $choice öffnet ChatGPT mit der gewählten Küche', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(MaterialApp(
        home: FoodModePage(
          mode: FoodMode.dineOut,
        ),
      ));
      // The app scaffold can keep an indeterminate animation alive, so
      // avoid pumpAndSettle here; this test only needs the initial layout.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final choiceCard = find.byKey(ValueKey<String>('food_choice_dineOut_$choice'));
      expect(choiceCard, findsOneWidget, reason: 'Auswahl $choice fehlt');
      final tapTarget = find.byKey(ValueKey<String>('food_choice_tap_dineOut_$choice'));
      expect(tapTarget, findsOneWidget, reason: 'Klickziel für $choice fehlt');
      await tester.ensureVisible(tapTarget);
      // Invoke the actual InkWell callback. The page contains a shrink-wrapped
      // grid inside a scroll view, whose hit-test geometry is unreliable in
      // this widget test; this still exercises the production navigation path.
      tester.widget<InkWell>(tapTarget).onTap!.call();
      // Location lookup intentionally shows a progress indicator and may not
      // settle in widget tests without native geolocation platform channels.
      // Pump the route transition for a bounded duration instead of waiting
      // for every animation in the new page to become idle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ChatGptRestaurantPage), findsOneWidget);
      // The auto-launch flow deliberately hides the restaurant form until
      // location lookup finishes, so Android's permission dialog has a neutral
      // background rather than the previous app screen.
      expect(find.text('Love'), findsOneWidget);
      expect(find.text('Standort wird ermittelt …'), findsNothing);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    });
  }

}
