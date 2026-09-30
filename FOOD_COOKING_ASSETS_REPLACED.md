# Cooking Food-Choice Assets – Replacement Report

## Änderungen

- Die fünf bestehenden Assets unter `assets/food_choices/cooking/` wurden durch die neu erstellten Gerichts-Grafiken ersetzt.
- Verwendete Zuordnung:
  - `schwein.png` → Schweinefleischgericht
  - `huhn.png` → Hühnergericht
  - `fisch.png` → Fischgericht
  - `rind.png` → Rindfleischgericht
  - `vegetarisch.png` → vegetarisches Gericht
- Die bereitgestellte Sammelgrafik wurde in fünf einzelne Assets aufgeteilt.
- Die in der Sammelgrafik enthaltenen Kategorie-Texte und Symbole wurden aus den Einzelassets herausgeschnitten, damit die bestehende Flutter-Oberfläche ihre vorhandenen Labels weiterhin selbst darstellen kann und keine doppelte Beschriftung entsteht.
- Die bestehende Asset-Zuordnung in `lib/core/services/food_choice_asset_service.dart` musste nicht geändert werden, da die vorhandenen Pfade bereits exakt auf diese fünf Dateien zeigen.
- `pubspec.yaml` enthält den Cooking-Asset-Ordner bereits; keine Änderung erforderlich.
- Die bestehende `FoodModePage`-UI, Auswahl- und Navigationslogik wurde nicht verändert.
- Andere Food-Choice-Bereiche wie Bestellen und Wir gehen essen wurden nicht verändert.

## Verifikation

- Alle fünf neuen PNG-Dateien existieren unter dem erwarteten Cooking-Asset-Pfad.
- Die bestehenden Asset-Referenzen zeigen weiterhin auf die fünf Dateien.
- Flutter/Dart ist in der aktuellen Ausführungsumgebung nicht verfügbar; daher wurden `flutter analyze` und Flutter-Tests nicht ausgeführt und nicht als erfolgreich behauptet.
