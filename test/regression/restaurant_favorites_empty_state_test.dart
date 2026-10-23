import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty favorites state is clear and explains how to add the first one', () {
    final source = File('lib/features/settings/restaurant_favorites_page.dart').readAsStringSync();
    expect(source, contains('Noch keine Lieblingsrestaurants vorhanden'));
    expect(source, contains('Füge dein erstes Lieblingsrestaurant hinzu. Es erscheint dann hier und du kannst es direkt auswählen.'));
    expect(source, contains("label: const Text('Lieblingsrestaurant hinzufügen')"));
    expect(source, contains("title: const Text('Lieblingsrestaurants')"));
    expect(source, contains('color: AppDesign.surface'));
    expect(source, contains("Text('💛', style: TextStyle(fontSize: 42, height: 1.1))"));
    expect(source, isNot(contains('Icons.restaurant_menu_rounded')));
  });

  test('load failure remains distinct from an empty list and is readable', () {
    final source = File('lib/features/settings/restaurant_favorites_page.dart').readAsStringSync();
    expect(source, contains('Lieblingsrestaurants konnten nicht geladen werden.'));
    expect(source, contains('Bitte prüfe deine Verbindung und versuche es erneut.'));
    expect(source, contains('Icons.cloud_off_rounded'));
    expect(source, contains("FilledButton(onPressed: _load, child: const Text('Erneut versuchen'))"));
  });
}
