import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String source(String path) => File(path).readAsStringSync();

void main() {
  test('global navigation remains outside the content navigator', () {
    final shell = source('lib/core/app_shell.dart');

    expect(shell, contains('GlobalKey<NavigatorState> _contentNavigatorKey'));
    expect(shell, contains('body: Navigator('));
    expect(shell, contains('key: _contentNavigatorKey'));
    expect(shell, contains('bottomNavigationBar: SafeArea('));
    expect(shell, contains('child: NavigationBar('));
    expect(shell, contains('popUntil((route) => route.isFirst)'));
  });

  test('shell keeps main content reactive when the global tab changes', () {
    final shell = source('lib/core/app_shell.dart');

    expect(shell, contains('ValueNotifier<int> _contentIndex'));
    expect(shell, contains('ValueListenableBuilder<int>('));
    expect(shell, contains('index: selectedIndex'));
    expect(shell, contains('_contentIndex.value = value'));
  });

  test('normal feature navigation uses the shell navigator context', () {
    final files = [
      'lib/features/shared/today_page.dart',
      'lib/features/shared/shopping_list_page.dart',
      'lib/features/recipes/saved_recipes_page.dart',
      'lib/features/recipes/recipe_detail_page.dart',
      'lib/features/settings/settings_page.dart',
      'lib/features/settings/notifications_page.dart',
      'lib/features/shared/connection_page.dart',
      'lib/features/shared/recipe_suggestions_page.dart',
      'lib/features/food_modes/food_mode_page.dart',
    ];

    for (final file in files) {
      final text = source(file);
      expect(text, contains('Navigator'), reason: '$file must retain navigation actions');
      expect(text, isNot(contains('rootNavigator: true')), reason: '$file must not bypass the shell navigator');
    }
  });

  test('onboarding remains intentionally outside the authenticated app shell', () {
    final startup = source('lib/core/startup_page.dart');
    expect(startup, contains('FoodOnboardingPage'));
    expect(startup, contains('AppShell'));
  });
}
