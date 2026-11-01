import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('liked foods show a red heart during first-run onboarding', () {
    final source = File('lib/features/foods/food_onboarding_page.dart').readAsStringSync();
    expect(source, contains("value == 'like' ? Colors.red : AppDesign.divider"));
    expect(source, contains("_CountPill(icon: Icons.favorite_rounded, text: '$liked', color: Colors.red)"));
    expect(source, contains('constraints: const BoxConstraints(minWidth: 48, minHeight: 36)'));
    expect(source, contains('visualDensity: const VisualDensity(horizontal: 0, vertical: -3)'));
  });

  test('food preference changes upsert on the user and food unique key', () {
    final source = File('lib/data/repositories/food_repository.dart').readAsStringSync();
    expect(source, contains("onConflict: 'user_id,food_id'"));
    expect(source, contains("'preference': preference"));
  });
}
