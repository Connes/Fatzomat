import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Rezeptkopf zeigt den Namen zentriert ohne dekoratives Koch-Icon', () {
    final source = File('lib/features/recipes/recipe_detail_page.dart').readAsStringSync();

    expect(source, contains('textAlign: TextAlign.center'));
    expect(source, isNot(contains('Icons.soup_kitchen_rounded')));
    expect(source, isNot(contains('width: 52,\n                  height: 52,')));
  });
}
