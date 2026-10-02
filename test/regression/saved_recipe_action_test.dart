import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V84 retains the saved-recipe shopping action and current version', () {
    final source = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('version: 1.13.46+262'));
    expect(source, contains("Zur Einkaufsliste hinzufügen"));
    expect(source, contains("shareRecipeForToday"));
    expect(source, contains("_ServingsDialog"));
  });
}
