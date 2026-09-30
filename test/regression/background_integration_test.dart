import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V86 integrates the shared background scaffold into app screens', () {
    const expected = <String, String>{
      'food_modes/food_mode_page.dart': 'recipes',
      'foods/food_onboarding_page.dart': 'settings',
      'foods/food_preferences_page.dart': 'settings',
      'recipes/recipe_builder_page.dart': 'recipes',
      'recipes/recipe_detail_page.dart': 'recipeDetail',
      'recipes/saved_recipes_page.dart': 'recipes',
            'settings/diagnostics_page.dart': 'settings',
      'settings/notifications_page.dart': 'notifications',
      'settings/settings_page.dart': 'settings',
      'shared/connection_page.dart': 'share',
      'shared/decision_request_page.dart': 'decision',
      'shared/personalized_surprise_page.dart': 'decisionResult',
      'shared/today_page.dart': 'today',
    };

    for (final entry in expected.entries) {
      final source = File('lib/features/${entry.key}').readAsStringSync();
      expect(source, contains('TogetherScaffold('), reason: entry.key);
      expect(source, contains('backgroundType: TogetherBackgroundType.${entry.value}'), reason: entry.key);
    }

    final shell = File('lib/core/app_shell.dart').readAsStringSync();
    expect(shell, contains('backgroundColor: Colors.transparent'));
  });
}
