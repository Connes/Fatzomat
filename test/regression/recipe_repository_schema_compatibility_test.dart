import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saved recipe collection does not require the later recipes.updated_at column', () {
    final source = File('lib/data/repositories/recipe_repository.dart').readAsStringSync();
    expect(source, contains(".select('id,created_by,name,description,servings,prep_time_minutes,cook_time_minutes,difficulty,instructions,image_url,image_path,created_at,recipe_ingredients(*)')"));
    expect(source, contains(".order('created_at', ascending: false);"));
    expect(source, isNot(contains(".order('updated_at', ascending: false)")));
    expect(source, isNot(contains("image_url,created_at,updated_at,recipe_ingredients(*)")));
  });
}
