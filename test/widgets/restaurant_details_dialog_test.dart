import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app_mvp/features/shared/restaurant_details_dialog.dart';

void main() {
  Future<void> openDetails(
    WidgetTester tester, {
    Future<bool> Function()? onCompleteVisit,
    Future<bool> Function(bool currentlyFavorite)? onToggleFavorite,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await showRestaurantDetailsDialog(
                  context,
                  const {'name': 'Testrestaurant'},
                  onCompleteVisit: onCompleteVisit,
                  onToggleFavorite: onToggleFavorite,
                );
              },
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
  }

  testWidgets('completion ignores duplicate taps while the request is in flight',
      (tester) async {
    final completion = Completer<bool>();
    var calls = 0;
    bool? dialogResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                dialogResult = await showRestaurantDetailsDialog(
                  context,
                  const {'name': 'Testrestaurant'},
                  onCompleteVisit: () {
                    calls++;
                    return completion.future;
                  },
                );
              },
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();

    final done = find.widgetWithText(TextButton, 'Erledigt');
    await tester.tap(done);
    await tester.pump();

    expect(calls, 1);
    expect(tester.widget<TextButton>(done).onPressed, isNull);

    await tester.tap(done);
    await tester.pump();
    expect(calls, 1);

    completion.complete(true);
    await tester.pumpAndSettle();
    expect(dialogResult, isTrue);
    expect(find.text('Erledigt'), findsNothing);
  });

  testWidgets('completion failure keeps the dialog open and re-enables the action',
      (tester) async {
    await openDetails(
      tester,
      onCompleteVisit: () async => throw StateError('network failure'),
    );

    final done = find.widgetWithText(TextButton, 'Erledigt');
    await tester.tap(done);
    await tester.pump();
    await tester.pump();

    expect(find.text('Testrestaurant'), findsOneWidget);
    expect(tester.widget<TextButton>(done).onPressed, isNotNull);
    expect(
      find.text('Besuch konnte nicht abgeschlossen werden. Bitte versuche es erneut.'),
      findsOneWidget,
    );
  });

  testWidgets('favorite toggle is serialized and updates only after success',
      (tester) async {
    final toggle = Completer<bool>();
    var calls = 0;

    await openDetails(
      tester,
      onToggleFavorite: (_) {
        calls++;
        return toggle.future;
      },
    );

    final favorite = find.byTooltip('Als Lieblingsrestaurant speichern');
    final favoriteButton = find.ancestor(
      of: favorite,
      matching: find.byType(IconButton),
    ).first;
    await tester.tap(favorite);
    await tester.pump();

    expect(calls, 1);
    expect(tester.widget<IconButton>(favoriteButton).onPressed, isNull);

    await tester.tap(favorite);
    await tester.pump();
    expect(calls, 1);

    toggle.complete(true);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Aus Lieblingsrestaurants entfernen'), findsOneWidget);
  });

  testWidgets('favorite failure keeps the previous state and allows retry',
      (tester) async {
    var calls = 0;
    await openDetails(
      tester,
      onToggleFavorite: (_) async {
        calls++;
        if (calls == 1) throw StateError('network failure');
        return true;
      },
    );

    final favorite = find.byTooltip('Als Lieblingsrestaurant speichern');
    await tester.tap(favorite);
    await tester.pump();
    await tester.pump();

    expect(find.byTooltip('Als Lieblingsrestaurant speichern'), findsOneWidget);
    expect(
      find.text('Favorit konnte nicht aktualisiert werden. Bitte versuche es erneut.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Als Lieblingsrestaurant speichern'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byTooltip('Aus Lieblingsrestaurants entfernen'), findsOneWidget);
  });
}
