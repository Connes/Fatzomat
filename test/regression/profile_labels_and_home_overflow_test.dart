import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home decision button uses compact height to avoid compact-screen overflow', () {
    final home = File('lib/features/home/home_page.dart').readAsStringSync();
    expect(home, contains('const ctaHeight = 56.0;'));
    expect(home, contains('final groupHeight = welcomeHeight + gridHeight + ctaGap + ctaHeight;'));
  });

  test('settings navigation and profile labels use the new wording', () {
    final shell = File('lib/core/app_shell.dart').readAsStringSync();
    final profile = File('lib/features/settings/settings_page.dart').readAsStringSync();
    expect(shell, contains("label: 'Profil'"));
    expect(profile, contains("TogetherAppBar(title: Text('Profil'))"));
    expect(profile, contains("title: 'Lieblingsrestaurants'"));
    expect(profile, contains("subtitle: 'Deine gespeicherten Favoriten'"));
    expect(profile, contains("title: 'Connection'"));
    expect(profile, contains('color: const Color(0xFFD4AF37)'));
    expect(profile, contains('Icon(icon, color: const Color(0xFFD4AF37))'));
  });

  test('backup page only shows the create and restore actions without intro text', () {
    final backup = File('lib/features/settings/backup_page.dart').readAsStringSync();
    expect(backup, isNot(contains('Gesichert werden deine Lebensmittelentscheidungen')));
    expect(backup, contains("title: 'Erstellen'"));
    expect(backup, contains("title: 'Wiederherstellen'"));
  });
}
