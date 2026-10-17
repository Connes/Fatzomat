import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('food preference changes upsert on the user and food unique key', () {
    final source = File('lib/data/repositories/food_repository.dart').readAsStringSync();
    expect(source, contains("onConflict: 'user_id,food_id'"));
    expect(source, contains("'preference': preference"));
  });
}
