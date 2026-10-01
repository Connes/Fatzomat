import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String source(String path) => File(path).readAsStringSync();

void main() {
  test('V85 bumps the app version and covers the critical flow surfaces', () {
    final pubspec = source('pubspec.yaml');
    expect(pubspec, contains('version: 1.13.46+258'));

    final criticalPages = <String, String>{
      'lib/features/home/home_page.dart': 'Home',
      'lib/features/food_modes/food_mode_page.dart': 'FoodMode',
      'lib/features/recipes/saved_recipes_page.dart': 'SavedRecipes',
      'lib/features/shared/today_page.dart': 'Today',
      'lib/features/shared/connection_page.dart': 'Connection',
      'lib/features/shared/decision_request_page.dart': 'DecisionRequest',
      'lib/features/settings/notifications_page.dart': 'Notifications',
      'lib/features/settings/settings_page.dart': 'Settings',
    };

    for (final entry in criticalPages.entries) {
      final text = source(entry.key);
      expect(text, isNotEmpty, reason: '${entry.value} source must exist');
      expect(text, contains('Navigator'), reason: '${entry.value} must expose navigation actions');
    }
  });

  test('V85 makes Android back navigation deterministic at the app shell', () {
    final shell = source('lib/core/app_shell.dart');
    expect(shell, contains('PopScope'));
    expect(shell, contains('canPop: index == 0'));
    expect(shell, contains('if (index != 0)'));
    expect(shell, contains('index = 0;'));
    expect(shell, contains('_contentIndex.value = 0;'));
    expect(shell, contains('popUntil((route) => route.isFirst)'));
    expect(shell, contains('NavigationBar'));
  });

  test('V85 keeps critical screens accessible and actionable', () {
    final home = source('lib/features/home/home_page.dart');
    final modes = source('lib/features/food_modes/food_mode_page.dart');
    final today = source('lib/features/shared/today_page.dart');
    final connection = source('lib/features/shared/connection_page.dart');

    expect(home, contains('Semantics('));
    expect(home, contains("semanticLabel: 'Wir kochen'"));
    expect(home, contains("semanticLabel: 'Wir bestellen'"));
    expect(home, contains("semanticLabel: 'Wir gehen essen'"));
    expect(home, contains("semanticLabel: 'Überrasch mich'"));
    expect(home, contains("'Entscheide Du'"));
    expect(home, contains("sendDecisionMessage(type: 'ask')"));
    expect(modes, contains('button: true'));
    expect(today, contains("tooltip: '"));
    expect(connection, contains("label: const Text('Status prüfen')"));
    expect(connection, contains("label: const Text('Verbindung trennen')"));
    expect(connection, isNot(contains("label: const Text('Code kopieren')")));
    expect(connection, isNot(contains("label: const Text('Rezeptvorschläge')")));
  });

  test('V85 exposes persistent retry states and friendly errors', () {
    final errorView = source('lib/core/async_error.dart');
    final notifications = source('lib/features/settings/notifications_page.dart');
    final profile = source('lib/features/settings/settings_page.dart');
    final connection = source('lib/features/shared/connection_page.dart');
    final saved = source('lib/features/recipes/saved_recipes_page.dart');

    expect(errorView, contains('Erneut versuchen'));
    expect(errorView, isNot(contains('friendlyError(error)')));
    expect(errorView, contains('Deine Daten wurden nicht verändert'));
    expect(errorView, contains('if (!context.mounted) return;'));
    expect(notifications, contains('AppErrorView'));
    expect(profile, contains('AppErrorView'));
    expect(connection, contains('AppErrorView'));
    expect(saved, contains('showAppError(context, e)'));
  });

  test('V85 guards realtime lifecycle against uninitialized Supabase', () {
    final pages = [
      source('lib/features/shared/today_page.dart'),
      source('lib/features/shared/connection_page.dart'),
      source('lib/features/settings/settings_page.dart'),
      source('lib/features/settings/notifications_page.dart'),
      source('lib/features/recipes/saved_recipes_page.dart'),
    ];

    for (final text in pages) {
      expect(text, contains('on AssertionError'));
    }
  });
}
