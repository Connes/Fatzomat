# Release readiness v14

## Umgesetzt
- zentrale UI-Hilfe für verständliche Fehler-Snackbars
- Diagnose-Seite für Supabase-Konfiguration
- zusätzliche Core-Invariant-Tests
- einfacher struktureller Release-Check unter `tool/check_release.dart`

## Warum noch kein Store-Build
Ein echter iOS-/Android-Build braucht native Projektdateien, Signing-Konfiguration,
Bundle IDs/Application IDs und eine konkrete Domain für Universal/App Links. Diese
Daten liegen nicht vor und werden nicht erfunden.

## Nächster echter Release-Test
```bash
dart run tool/check_release.dart
flutter pub get
flutter analyze
flutter test
```

Danach in einer Testumgebung:
- Supabase Migrationen anwenden
- `supabase/tests/smoke.sql`
- RLS mit zwei Haushalten prüfen
- Realtime mit zwei Geräten prüfen
- Wochen-Einkauf mit doppelten Zutaten prüfen
- Einladungscode Ende-zu-Ende testen
