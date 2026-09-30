# Entwicklung v4

## Umgesetzt

- globaler primärer Haushalt per RPC ermittelbar
- gemeinsamer Essensplan als Realtime-Datenstrom
- Rezepte können für heute in den Essensplan übernommen werden
- Essensplan zeigt Rezept, Datum, Portionen und Ersteller
- Mitgliederliste
- Haushaltsscreen verlinkt Essensplan und Einkauf
- Home-Screen führt den Kernflow zusammen
- Realtime-Migration für meal_plans
- RLS für Lesen/Erstellen/Ändern/Löschen von Meal-Plans

## Neue Migration

`supabase/migrations/202609090004_meal_planning_and_invites.sql`

## Nächster Block

Als nächstes sollte die App visuell und funktional weiter Richtung Beta gehen:

1. echtes App-Navigations-/State-Management
2. kategorisierte Einkaufsliste
3. „Mein Wunsch fürs Abendessen“-Karten
4. Reaktionen/Abstimmung innerhalb des Haushalts
5. Wochenansicht statt nur „heute“
6. Teilen/Einladungen über Deep Link
7. Offline- und Fehlerzustände
8. Tests und Security Review
