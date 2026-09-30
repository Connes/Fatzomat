# Schmackofatz V1.6.8

## Stabilisierung und Fehlerbehandlung

- Die Version wird auf `1.6.8+168` angehoben.
- Zentrale Fehlerdarstellung bleibt als persistenter Retry-Zustand mit verständlicher Nutzerkommunikation erhalten.
- `showAppError` prüft den `BuildContext` vor der Anzeige und vermeidet damit veraltete UI-Zugriffe nach Navigation oder Disposal.
- Veraltete Fehlermeldungen zu einer nicht mehr verwendeten OpenAI-/KI-Rezept-API wurden aus der zentralen Nutzerfehlerbehandlung entfernt.
- Die bestehenden Realtime-Lifecycle-Schutzmaßnahmen bleiben erhalten.
- Die bestehenden leeren, Lade- und Fehlerzustände der kritischen Screens bleiben unverändert erhalten.

## Release

- Version: `1.6.8+168`
- Private Android-Version
- Kein OpenAI-API-Aufruf
- Kein neuer Supabase-Migrationsbedarf

## Korrektur nach Flutter-Analyse

- Fehlerhafte Dart-Import-Strings in mehreren Screens korrigiert.
- Versehentlich verbliebener Zugriff auf `decision.choice` korrigiert.
- Nicht-konstante Callback-Einträge aus der `const`-Liste des Heute-Leerzustands entfernt.
- Der Versionsstand bleibt `1.6.8+168`.
