# Schmackofatz v1.12.0 – Food-Onboarding Setup Redesign

## Änderung

Die bestehende Lebensmittel-Einrichtungsseite im Onboarding wurde visuell reduziert, ohne die bestehende Daten- und Abschlusslogik zu verändern.

- Der kompakte Schmackofatz-Brand-Header oberhalb der Einrichtung wurde entfernt.
- In der bestehenden „Kurz einrichten“-Box ersetzt das vorhandene echte App-Logo das bisherige Herz-Icon.
- App-Logo und „Kurz einrichten“ sind zentriert.
- „Lebensmittel suchen“ inklusive Suchfeld wurde aus der sichtbaren Onboarding-UI entfernt.
- „Lieblingsrezept speichern“ wurde aus der sichtbaren Onboarding-UI entfernt.
- Kategorien, Lebensmittel-Auswahl, „Mag ich“ / „Mag ich nicht“, eigenes Lebensmittel hinzufügen und „Los geht’s“ bleiben erhalten.
- Es wurden keine neuen Assets erzeugt.

## Logik

Die bestehenden Repository-Aufrufe und Abschlusslogik bleiben unverändert, insbesondere `FoodRepository`, `ProfileRepository().completeOnboarding(prefs)`, `prefs`, `finish()` und `widget.onCompleted()`.

## Tests

Der Food-Onboarding-Regressionstest wurde auf die neue Setup-Struktur ausgerichtet und prüft insbesondere das vorhandene App-Logo, die Zentrierung, die entfernten UI-Elemente sowie die erhaltene Lebensmittel- und Abschlusslogik.

## Verifikation

`flutter analyze` und `flutter test` konnten in der Erstellungsumgebung nicht ausgeführt werden, da dort kein Flutter/Dart-Executable vorhanden ist. Die Quelldateien wurden statisch auf ausgeglichene Klammer-/Klammerpaare und die im Regressionstest erwartete Struktur geprüft.
