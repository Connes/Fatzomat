# Einstellungen-Struktur V1.12.0

## Umsetzung

- Die bisherige Profilseite wurde zu `SettingsPage` unter `lib/features/settings/settings_page.dart` umgebaut.
- Die globale Bottom Navigation verwendet für diesen Bereich ausschließlich das Zahnrad-Icon und keinen sichtbaren Text.
- Die Einstellungsseite ist in `Meine Ernährung`, `Connections`, `Datensicherung` und `App` gegliedert.
- Bestehende Funktionen für Lebensmittel, persönliche Entscheidungen, Connections und Benachrichtigungen bleiben über Unterseiten erreichbar.
- Die bisherige Konto-/E-Mail-Sicherung wurde aus der Einstellungsoberfläche entfernt.
- Der anonyme Supabase-Start übermittelt keinen `display_name` mehr.
- Das lokale Backup exportiert keine Profil-/Namensdaten.
- Eine Backup-Wiederherstellung wurde nicht erfunden, weil die bestehende `BackupService`-Implementierung ausschließlich Export unterstützt.

## Verifikation

Die lokale Umgebung dieses Arbeitscontainers enthält kein `flutter` im `PATH`. Deshalb konnten `flutter analyze` und `flutter test` hier nicht ausgeführt werden. Die Änderung wurde statisch geprüft und die bestehenden source-basierten Regressionstests wurden auf die neue `SettingsPage`-Struktur angepasst bzw. um einen Settings-/Anonymitäts-Regressionstest ergänzt.
