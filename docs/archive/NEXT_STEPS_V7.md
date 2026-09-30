# v7

- Essenswunsch → Rezept → Annahme → Essensplan → Einkauf ist jetzt serverseitig verbunden.
- Zutaten werden bei Annahme automatisch auf die gewählte Personenzahl skaliert.
- Gleiche Artikel werden zusammengeführt.
- Startseite fokussiert den Kernworkflow.
- Essenswünsche sind direkt vom Start und Haushalt erreichbar.

Neue Migration:
`supabase/migrations/202609090006_accept_request_to_shopping.sql`

Vor Produktion:
- Migrationen in Supabase ausführen
- Flutter Analyzer/Tests ausführen
- RLS/Security prüfen
- Deployment konfigurieren
