# V62 · App-Icon Setup Fix

V61 hatte die `flutter_launcher_icons.yaml` im falschen Format. Das Paket erwartet die Konfiguration unter dem Schlüssel `flutter_launcher_icons:`.

V62 korrigiert:
- gültige `flutter_launcher_icons.yaml`
- Setup verwendet explizit `dart run flutter_launcher_icons --file flutter_launcher_icons.yaml`
- neues together Master-Icon bleibt `assets/branding/app_icon.png`
- Android, iOS und Web werden automatisch generiert

Start:
```bash
./setup.sh
```

Danach kann direkt gebaut werden:
```bash
flutter build apk
```
