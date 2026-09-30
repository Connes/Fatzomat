# Schmackofatz V1.6.3

## Einkauf & Portionsskalierung

- Der Heute-Controller wird jetzt sauber initialisiert und beim Verlassen des Screens freigegeben.
- Die Einkaufsliste zeigt die aktuell geplante Personenzahl direkt an.
- Die Einkaufsliste erklärt die Synchronisation der Rezeptmengen.
- Rezeptartikel werden bei Änderung der Personenzahl serverseitig neu skaliert.
- Manuell hinzugefügte Einkaufsartikel bleiben bei der Portionsänderung erhalten.
- Manuelle Einkaufsartikel bleiben als solche gekennzeichnet.
- Ein fehlerhafter Controller-Verweis im Dialog zum Bearbeiten von Einkaufsartikeln wurde entfernt.
- Versionsnummer: `1.6.3+163`.

## Bewusst unverändert

- Keine OpenAI-API.
- Kein Zwei-Personen-Runtime-Test in dieser Version.
- Supabase bleibt Backend für den heutigen Plan und die Einkaufsliste.
