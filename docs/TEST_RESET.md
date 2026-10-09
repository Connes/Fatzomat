# Fatzomat Test Reset

Dieser Reset ist ausschließlich für die Entwicklungs-/Testumgebung gedacht.

## Ablauf

1. Alle Testnutzer löschen.
2. Nutzerbezogene Testdaten bereinigen, einschließlich Today-Plänen, Einkaufslisten und Food-Präferenzen.
3. Ausgewählte Test-Stammdaten auf den definierten Sollbestand bringen.
4. Foreign-Key-Referenzen und verwaiste Daten prüfen.
5. Am Ende automatisch verifizieren: Nutzer = 0, Testdaten = 0, gewünschte Foods vorhanden, unerwünschte Foods nicht vorhanden.

Der Reset wird bewusst manuell und mit einer expliziten Bestätigung ausgeführt. Er ist kein App-Feature und keine normale Datenbankmigration.
