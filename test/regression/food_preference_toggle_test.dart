import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('liked foods show a red heart during first-run onboarding', () {
    final source = File('lib/features/foods/food_onboarding_page.dart').readAsStringSync();
    expect(source, contains("value == 'like' ? Colors.red : AppDesign.divider"));
  });

  test('food preference controls expose selected state to accessibility services', () {
    final source = File('lib/features/foods/food_onboarding_page.dart').readAsStringSync();
    expect(source, contains('toggled: value == \'like\''));
    expect(source, contains('toggled: value == \'dislike\''));
    expect(source, contains("'Mag ich (ausgewählt)' : 'Mag ich'"));
    expect(source, contains("'Mag ich nicht (ausgewählt)' : 'Mag ich nicht'"));
  });

  test('food preference changes upsert on the user and food unique key', () {
    final source = File('lib/data/repositories/food_repository.dart').readAsStringSync();
    expect(source, contains("onConflict: 'user_id,food_id'"));
    expect(source, contains("'preference': preference"));
  });
}
