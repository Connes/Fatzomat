# Schmackofatz v1.12.0 – Additional Ingredients Visual Update

## Änderungen

- Entfernt die unboxed Intro-Texte direkt unter „Weitere Zutaten“.
- Entfernt die Favoriten-Karte aus der Übersicht. Die bestehende Favoriten-Kategorie bleibt intern für den bestehenden Kategoriefluss erhalten.
- Aktiviert `extendBody` auf der Seite „Weitere Zutaten“, damit das vorhandene Rezept-Hintergrundbild hinter den unteren Aktionsbereich reicht und kein schwarzer Zwischenbereich sichtbar bleibt.
- Beibehaltung der vorhandenen Beilage-/Gemüse-Logik und Auswahlübernahme.
- Regressionstests an die neue Übersicht angepasst.

## Verifizierung

- Quelltext statisch geprüft.
- Flutter/Dart-Formatierung und Testlauf in dieser Umgebung nicht ausführbar, da `dart`/`flutter` nicht installiert sind.
