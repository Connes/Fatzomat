# Entwicklung v3

Umgesetzt:

- gespeicherte Rezepte als eigener Bereich
- vollständige Rezeptdetailseite
- Portionsgröße nachträglich ändern
- Zutatenmengen auf der Detailseite automatisch skalieren
- gespeichertes Rezept direkt zur Haushaltseinkaufsliste hinzufügen
- Mengen werden serverseitig anhand der gewünschten Portionen berechnet
- identische Zutaten werden zusammengeführt
- Rezept explizit mit einem Haushalt teilen
- Household/Meal-Plan-Berechtigungen für geteilte Rezepte ergänzt
- Home um gespeicherte Rezepte erweitert

Neue Migration:
`supabase/migrations/202609090003_saved_recipes_and_household_flow.sql`

Nach dem Anwenden der Migration ist der Flow:
Lebensmittel → KI-Rezept → Speichern → Rezept öffnen → Haushalt wählen → Einkaufsliste.

Hinweis:
Für eine produktive Version sollte als nächstes die Haushalt-Auswahl global im App-State gehalten werden, statt sie nur lokal auf einzelnen Screens zu laden. Danach folgt die Wochenplanung und eine bessere, kategorisierte Einkaufsliste.
