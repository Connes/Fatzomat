# Version 23: feste Supabase-Client-Konfiguration

Ab v23 müssen in Android Studio keine `Additional run args` mehr eingetragen werden.

Die Flutter-App verwendet die Supabase-URL und den Supabase-Publishable-Key aus:

```text
lib/core/config.dart
```

Damit genügt in Android Studio der normale **Run ▶**-Button.

## Sicherheit

Der verwendete `sb_publishable_...` Key ist für den Client vorgesehen. Der Supabase-Secret-Key darf niemals in Flutter-Code, Git oder die APK gelangen.

Die Datenbank wird weiterhin über Supabase RLS geschützt.

OpenAI-Zugangsdaten bleiben ausschließlich als Secret der Supabase Edge Function konfiguriert.

## Android-Projekt

Falls die ZIP ohne `android/` geliefert wurde, einmalig im Projektverzeichnis ausführen:

```bash
flutter create --platforms=android .
```

Danach Android Studio neu laden und normal mit **Run ▶** starten.
