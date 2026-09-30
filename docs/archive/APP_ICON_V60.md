# App Icon V60

Das neue together-Logo ist als Launcher-Icon konfiguriert.

Quelle: `assets/branding/app_icon.png`

Die Konfiguration verwendet `flutter_launcher_icons` 0.14.4 für Android, iOS und Web.

## Einmalig lokal ausführen

```bash
flutter pub get
dart run flutter_launcher_icons
```

Danach neu bauen:

```bash
flutter clean
flutter build apk
```

Falls `android/` oder `ios/` in einem Source-ZIP fehlen, einmalig:

```bash
flutter create .
```

Dabei vorhandene `lib/`, `assets/`, `pubspec.yaml` und Supabase-Dateien nicht löschen oder überschreiben.
