# Plattformdateien sind Release-Bestandteil

V1.4 erzeugt Android/iOS nicht automatisch. Das ist absichtlich so: `flutter create` darf keine bestehende Plattformkonfiguration während eines Release-Setups überschreiben.

Ein vollständiger Checkout muss mindestens enthalten:

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

Die Dateien werden durch den Repository- und Release-Check geprüft. In einer Flutter-Entwicklungsumgebung kann ein neues Projekt einmalig mit `flutter create --platforms=android,ios .` initialisiert und anschließend versioniert werden. Danach darf `setup.sh` diese Struktur nicht erneut generieren.
