# Android Studio Setup – v26

Das Projekt bringt die relevanten Android-Studio-Projektdateien mit.

Automatisch eingerichtet werden:

- Dart SDK: `/home/matthias/flutter/bin/cache/dart-sdk`
- Flutter-Modul: `food_app_mvp_starter_v26.iml`
- Run Configuration: `food_app`
- Supabase `--dart-define` Parameter
- Android-Struktur, falls sie fehlt

## Neues ZIP

Nach dem Entpacken:

```bash
cd ~/Projekt/food/food_app_mvp_starter_v26
chmod +x setup.sh
./setup.sh
```

Danach Android Studio öffnen.

**Hinweis:** Android Studio kann eigene `.idea`-Metadaten neu erzeugen. Deshalb repariert `setup.sh` die Konfiguration jedes Mal automatisch, falls sie fehlt.
