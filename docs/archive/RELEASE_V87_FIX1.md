# V87 Fix 1

## Stabilitätsfix für Setup und Home

- Syntaxfehler in `home_page.dart` behoben.
- Flutter-Versionsausgabe im `setup.sh` ohne früh abbrechende Pipe, damit kein Broken-Pipe-Fehler entsteht.
- Launcher-Icon-Erzeugung nutzt das mit Flutter ausgelieferte Dart SDK direkt statt des veralteten `flutter pub run` Aufrufs.
- Web-Icon-Generierung deaktiviert, da dieses Projekt Android/iOS erzeugt und kein `web/` Verzeichnis voraussetzt.
- Versionsnummer bleibt `0.1.0+87`.
