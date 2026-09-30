# Food App v24 – automatisches Setup

## Neues ZIP-Projekt einrichten

Nach dem Entpacken im Projektordner:

```bash
./setup.sh
```

Das Skript:

1. prüft, ob Flutter verfügbar ist
2. erzeugt `android/` automatisch, falls es fehlt
3. führt `flutter pub get` aus
4. führt `flutter analyze` aus
5. führt `flutter test` aus

Danach kann das Projekt direkt in Android Studio geöffnet und mit **Run ▶** gestartet werden.

## Supabase

Die Client-Konfiguration befindet sich in:

```text
lib/core/config.dart
```

Es werden keine Additional Run Args benötigt.

Der Supabase Publishable Key darf im Client verwendet werden.
Ein Supabase Secret Key gehört niemals in dieses Projekt.
