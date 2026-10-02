import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V19 bietet den stabilen together_recipe Export aus Rezeptdetails', () {
    final service = File('lib/data/services/together_recipe_file_service.dart').readAsStringSync();
    final detail = File('lib/features/recipes/recipe_detail_page.dart').readAsStringSync();
    final model = File('lib/data/models/recipe.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('version: 1.13.46+262'));
    expect(service, contains('Future<bool> saveRecipe(Recipe recipe'));
    expect(service, contains("allowedExtensions: const ['json']"));
    expect(service, contains('toTogetherRecipeJson()'));
    expect(detail, contains("tooltip: 'Rezeptdatei speichern'"));
    expect(detail, contains('exportRecipe'));
    expect(model, contains("'format': 'together_recipe'"));
    expect(model, contains("'version': 1"));
  });
}
