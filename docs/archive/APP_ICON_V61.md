# App Icon / Setup V61

Das Setup wurde automatisiert erweitert:

- fehlende Android- und iOS-Plattformstruktur wird erzeugt
- Android-Studio-/Dart-Modul wird dynamisch aus dem `name:`-Eintrag der `pubspec.yaml` erzeugt
- alte hartcodierte `.iml`-Dateien werden entfernt
- `assets/branding/app_icon.png` ist die einzige Masterquelle für das together-Icon
- `flutter pub run flutter_launcher_icons` wird automatisch nach `flutter pub get` ausgeführt
- Android, iOS und Web Launcher-Icons werden dadurch automatisch aktualisiert
- `flutter analyze` und `flutter test` laufen weiterhin automatisch

## Einmaliger Ablauf

```bash
./setup.sh
```

Danach kann Android Studio das Projekt neu öffnen. Ein manuelles „Enable Dart support“ sollte bei einer frisch geöffneten Projektstruktur nicht mehr erforderlich sein.
