import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String source(String path) => File(path).readAsStringSync();

void main() {
  test('Einstellungen ersetzt Profil in der globalen Navigation', () {
    final shell = source('lib/core/app_shell.dart');

    expect(shell, contains('const SettingsPage()'));
    expect(shell, contains('Icons.settings_outlined'));
    expect(shell, contains('Icons.settings_rounded'));
    expect(shell, contains("label: ''"));
    expect(shell, isNot(contains("label: 'Profil'")));
    expect(shell, isNot(contains('Icons.person_outline_rounded')));
  });

  test('Einstellungsseite verwendet die neue Struktur ohne Account-UI', () {
    final settings = source('lib/features/settings/settings_page.dart');

    expect(settings, contains("title: Text('Einstellungen')"));
    expect(settings, contains('Meine Ernährung'));
    expect(settings, contains("title: connected ? 'Meine Connection' : 'Connection hinzufügen'"));
    expect(settings, contains("title: 'Backup erstellen'"));
    expect(settings, isNot(contains('_SettingsIntro')));
    expect(settings, isNot(contains("SectionHeader(title: 'Meine Ernährung')")));
    expect(settings, isNot(contains("SectionHeader(title: 'Connections')")));
    expect(settings, isNot(contains("SectionHeader(title: 'Datensicherung')")));
    expect(settings, isNot(contains("SectionHeader(title: 'App')")));
    expect(settings, contains('Benachrichtigungen'));
    expect(settings, isNot(contains('Schmackofatz kann anonym genutzt werden. Das Backup ist optional und dient der Datensicherung.')));
    expect(settings, isNot(contains('Konto sichern')));
    expect(settings, isNot(contains('E-Mail-Adresse')));
    expect(settings, isNot(contains('Anmelden')));
  });

  test('Anonymer Start sendet keinen Benutzernamen an Supabase', () {
    final main = source('lib/main.dart');
    final diagnostics = source('lib/features/settings/diagnostics_page.dart');

    expect(main, contains('auth.signInAnonymously();'));
    expect(main, isNot(contains('display_name')));
    expect(diagnostics, contains('auth.signInAnonymously();'));
    expect(diagnostics, isNot(contains('display_name')));
  });

  test('Backup exportiert keine Profil-/Namensdaten', () {
    final backup = source('lib/data/services/backup_service.dart');

    expect(backup, contains('profile: null'));
    expect(backup, isNot(contains('select(\'display_name,onboarding_completed\')')));
  });
}
