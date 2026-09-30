# Schmackofatz v1.12.0 – Ingredient Category Visual Update

## Änderungen

- Entfernt die unboxed Untertitel direkt unter den Überschriften „Beilage auswählen“ und „Gemüse auswählen“.
- Aktiviert `extendBody` auf den Kategorie-Auswahlseiten, damit das vorhandene Rezept-Hintergrundbild bis hinter den unteren Aktionsbereich reicht.
- Dadurch wird der schwarze Zwischenbereich oberhalb der Navigation nicht mehr durch den Scaffold-Hintergrund sichtbar.
- Die bestehende Auswahl-, Lade-, Fehler- und Übernahmelogik bleibt unverändert.

## Verifizierung

- Quelltext statisch geprüft.
- Regressionstest für entfernten Untertitel und `extendBody` ergänzt.
- Flutter/Dart-Testlauf in dieser Umgebung nicht ausführbar, da `dart`/`flutter` nicht installiert sind.
