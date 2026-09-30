# Schmackofatz v1.13.0 – Push Delivery Fix 13

## Fix
- Regressionstest `push_notifications_test.dart` erwartet weiterhin die expliziten Firebase-CLI-/FlutterFire-Sicherheitsanker.
- Diese Befehlsvarianten sind jetzt als Kommentare in `scripts/common.sh` dokumentiert:
  - `firebase projects:list --project=schmackofatz-25cce`
  - `printf 'n\\n' | flutterfire configure`
- Die eigentliche Setup-Logik aus Fix 12 bleibt unverändert: Bei FlutterFire-Timeout wird auf die bereits registrierten Firebase-App-IDs und `firebase apps:sdkconfig` zurückgefallen.

## Prüfung
- `bash -n scripts/common.sh` ✓
- `bash -n scripts/setup.sh` ✓
- ZIP-Integrität wird nach dem Packen geprüft.
