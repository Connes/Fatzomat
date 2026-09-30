# together App Icon V63

## Fix

Das Setup verwendet jetzt `flutter pub run flutter_launcher_icons` statt eines direkten `dart`-Aufrufs.

Damit funktioniert die Icon-Generierung auch auf Systemen, auf denen `dart` nicht separat im PATH liegt.

## Einmaliger Aufruf

```bash
./setup.sh
```

Das Setup führt anschließend automatisch `flutter pub get`, die Icon-Generierung, `flutter analyze` und `flutter test` aus.
