# Android Studio Setup – v25

Dieses Projekt enthält eine versionierte Android-Studio-Konfiguration.

## Enthalten

- Dart SDK:
  `/home/matthias/flutter/bin/cache/dart-sdk`
- Flutter Run Configuration:
  `food_app`
- Additional Run Args:
  `--dart-define=SUPABASE_URL=https://oidxezjdwqktpxuypbfb.supabase.co`
  `--dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_wArlWtPig52UQJdvIcEWCw_dtiPRNpt`

## Verwendung

Projekt in Android Studio öffnen und die Run Configuration `food_app` auswählen.
Danach **Run ▶**.

Falls Android Studio fragt, ob Projektdateien aus der Versionsverwaltung übernommen werden sollen, die Projektkonfiguration akzeptieren.

## Hinweis

Der Dart-SDK-Pfad ist absichtlich auf die lokale Flutter-Installation des Entwicklungsrechners gesetzt.
Der Publishable Key ist für die Client-App bestimmt. Ein Supabase Secret Key gehört niemals in diese Konfiguration.
