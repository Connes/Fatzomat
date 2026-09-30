# Schmackofatz v1.12.0 – Manual Recipe Form Visual Update

## Änderung

Die Seite **„Rezept manuell erstellen“** wurde visuell an den aktuellen Schmackofatz-Stil angepasst.

### UI

- Hintergrundbild bleibt über die gesamte Inhaltsfläche sichtbar und läuft hinter den unteren Speichern-Aktionsbereich.
- Schwarzer Bereich hinter dem unteren Aktionsbutton entfällt durch transparenten Scaffold-Bereich und `extendBody`.
- Formularfelder sind in klar abgegrenzten, hellen Karten dargestellt.
- Wichtige Felder besitzen ein konsistentes grünes Icon-Feld zur besseren visuellen Orientierung.
- Labels und Hinweise werden mit ausreichend Kontrast und dauerhaft sichtbarem Label dargestellt.
- Zutaten und Zubereitung sind als eigene Bereiche mit klarer Überschrift und App-Style-Aktionsbutton organisiert.
- Zutaten-/Schritt-Editoren behalten ihre bestehende Funktionalität einschließlich Entfernen, Mengen- und Einheitenauswahl.
- Der Speichern-Button verwendet das zentrale App-Grün und bleibt über dem Hintergrundbild lesbar.

## Verhalten

Die bestehende Speicherlogik, Validierung und Datenstruktur wurden nicht verändert.

## Verifizierung

- Statische Architekturprüfung: erfolgreich.
- Flutter/Dart-Analyse und Widget-Tests: nicht ausgeführt, da Flutter/Dart in der aktuellen Umgebung nicht installiert sind.
