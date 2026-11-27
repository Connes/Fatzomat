import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recipe category filter shows a gold icon for every option', () {
    final source = File('lib/features/recipes/saved_recipes_page.dart').readAsStringSync();
    final categoryFilterStart = source.indexOf("tooltip: 'Nach Rezeptart filtern'");
    final categoryFilterEnd = source.indexOf("title: const Text('Meine Rezepte')", categoryFilterStart);
    expect(categoryFilterStart, isNonNegative);
    expect(categoryFilterEnd, greaterThan(categoryFilterStart));

    final filter = source.substring(categoryFilterStart, categoryFilterEnd);
    expect(filter, contains("('Alle', Icons.grid_view_rounded)"));
    expect(filter, contains("('Hauptgericht', Icons.restaurant_menu_rounded)"));
    expect(filter, contains("('Süßspeise', Icons.cake_rounded)"));
    expect(filter, contains("('Beilage', Icons.dinner_dining_rounded)"));
    expect(filter, contains("('Salat', Icons.eco_rounded)"));
    expect(filter, contains("('Suppe', Icons.soup_kitchen_rounded)"));
    expect(filter, contains("('Snack', Icons.fastfood_rounded)"));
    expect(filter, contains("('Frühstück', Icons.free_breakfast_rounded)"));
    expect(filter, contains('color: AppDesign.iconGold'));
    expect(filter, contains('Icon(option.$2'));
    expect(filter, contains("value == 'Alle' ? 'Alle Rezeptarten' : value"));
  });
}
