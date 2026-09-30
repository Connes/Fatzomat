# Food App MVP v39

v39 ist eine technische Bereinigungsrunde vor dem nächsten größeren Feature-Ausbau.

## Start

`setup.sh` im Projektordner ausführen. Das Skript erkennt Flutter automatisch, richtet Android Studio ein und führt `flutter pub get`, `flutter analyze` und `flutter test` aus.

Die Supabase-Werte werden ausschließlich über `--dart-define` an die App übergeben.

## Supabase

Die produktive Datenbank wurde bereinigt und sicherer/performanter gemacht:

- alte Household-/Meal-Plan-/Shopping-Strukturen entfernt
- Lebensmittelkategorien vereinheitlicht
- relevante Foreign-Key-Indizes ergänzt
- Profil-RLS optimiert
- `handle_new_user()` nicht mehr als öffentliches RPC ausführbar

Die Edge Function `generate-recipes` ist produktiv auf **Version 4** und verwendet weiterhin JWT-Prüfung. Sie enthält die zusätzliche Validierung für Pflichtzutaten, doppelte Zutaten, Einheiten, Auswahlmarkierungen und vegetarische Regeln.
