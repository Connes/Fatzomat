import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V84 keeps the saved-recipe actions aligned with the current menu', () {
    final source = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('version: 1.13.46+262'));
    expect(source, isNot(contains("PopupMenuItem(value: 'shopping'")));
    expect(source, contains("shareRecipeForToday"));
    expect(source, contains("_ServingsDialog"));
  });
}
