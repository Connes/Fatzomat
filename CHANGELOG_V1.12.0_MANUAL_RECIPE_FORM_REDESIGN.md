# Schmackofatz v1.12.0 – Manuelle Rezept-Erstellung

## Änderung

Die Seite „Rezept manuell erstellen“ wurde für kleine Smartphone-Breiten überarbeitet:

- Rezept-Metadaten werden nicht mehr in drei zu schmale Felder in einer Zeile gezwängt.
- Zutatenname steht auf einer eigenen, vollbreiten Zeile.
- Menge und Einheit stehen gemeinsam in einer ausreichend breiten Zeile.
- Menge ist über einen bestehenden Material-Dropdown auswählbar.
- Einheit ist über einen bestehenden Material-Dropdown mit üblichen Rezept-Einheiten auswählbar.
- Der vorhandene Button „Rezept speichern“ und die bestehende `RecipeRepository().saveRecipeModel(...)`-Logik bleiben erhalten.
- Bestehende Validierung und Navigation nach erfolgreichem Speichern bleiben erhalten.
- Keine neuen Dependencies oder Assets.

## Tests

Der bestehende Regressionstest für die Rezeptseite wurde um Prüfungen für Menge, Einheit, Dropdown-Auswahl und den bestehenden Speicherbutton ergänzt.

Flutter/Dart ist in der Arbeitsumgebung nicht verfügbar; `flutter analyze` und `flutter test` konnten daher hier nicht ausgeführt werden.

- Wiederhergestellt: bestehende `RecipeImportPreviewPage`- und `_SectionTitle`-Implementierungen, die beim vorherigen Patch versehentlich fehlten.
- `DropdownButtonFormField` auf `initialValue` umgestellt, passend zu Flutter 3.47.2.
