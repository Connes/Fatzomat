# Nächster Entwicklungsstand

## Neu umgesetzt

- Rezept speichern
- Zutaten eines gespeicherten Rezepts in eine gemeinsame Einkaufsliste übernehmen
- Zutaten werden bei gleicher `food_id` + Einheit zusammengeführt
- Einkaufsliste live via Supabase Stream
- Artikel abhaken
- Artikel bearbeiten
- Artikel per Swipe löschen
- abgehakte Artikel löschen
- manuelle Artikel hinzufügen
- persönliche App erstellen
- Einladungscode anzeigen
- persönliche App per Einladungscode beitreten
- gemeinsame Einkaufsliste automatisch beim persönliche App anlegen
- RLS/Grants für den Client ergänzt

## Migration

Nach der ersten Migration zusätzlich ausführen:

`supabase/migrations/202609090002_collaboration_and_shopping.sql`

## Realtime

Die Einkaufsliste verwendet `stream(primaryKey: ['id'])`. Supabase dokumentiert `stream()` als Kombination aus initialem Datenabruf und Realtime-Änderungen; Realtime muss für die betreffende Tabelle aktiviert sein.

## Bekannter nächster Schritt

Die UI zum Auswählen eines persönliche Apps und zum Hinzufügen eines gespeicherten Rezepts zur Einkaufsliste sollte als nächstes ergänzt werden. Danach ist der komplette Kernflow geschlossen:

Lebensmittel → Rezept → Speichern → persönliche App → Einkaufsliste → Realtime.
