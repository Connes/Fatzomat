import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty favorites state is clear and explains how to add the first one', () {
    final source = File('lib/features/settings/restaurant_favorites_page.dart').readAsStringSync();
    expect(source, contains('Noch keine Lieblingsrestaurants vorhanden'));
    expect(source, contains('Füge über das Plus oben rechts dein erstes Lieblingsrestaurant hinzu.'));
    expect(source, contains('color: AppDesign.surface'));
  });

  test('load failure remains distinct from an empty list and is readable', () {
    final source = File('lib/features/settings/restaurant_favorites_page.dart').readAsStringSync();
    expect(source, contains('Lieblingsrestaurants konnten nicht geladen werden.'));
    expect(source, contains('Bitte prüfe deine Verbindung und versuche es erneut.'));
    expect(source, contains('Icons.cloud_off_rounded'));
    expect(source, contains("FilledButton(onPressed: _load, child: const Text('Erneut versuchen'))"));
  });
}
