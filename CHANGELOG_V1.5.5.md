# Schmackofatz V1.5.5

## JSON-Import stabilisiert

- Version `1.5.5+155`.
- Der JSON-Import verwendet beim Dateiauswahldialog nicht mehr `withData: true`.
- Die ausgewählte Datei wird bevorzugt über den bereitgestellten Stream gelesen und nur bei Bedarf über den lokalen Pfad.
- Damit wird der native Android-Dateipicker nicht mehr gezwungen, die komplette Datei bereits während der Auswahl als Bytes bereitzustellen.
- Das ist besonders für Dateien aus Android-Dokument-Providern wie Downloads oder Cloud-Speichern robuster.
- Ungültige UTF-8-Dateien werden sauber als Importfehler behandelt.
