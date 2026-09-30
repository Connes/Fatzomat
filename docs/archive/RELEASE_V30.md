# Release v31

- Erstes Start-Onboarding für Lebensmittel nach Kategorien.
- Drei Zustände: Verwenden, Nicht verwenden, später entscheiden.
- Pro Kategorie „Alle verwenden“ / „Keine verwenden“.
- Onboarding wird in `profiles.onboarding_completed` gespeichert.
- Eigene Lebensmittel können im Onboarding und später unter Lebensmittel angelegt werden.
- Eigene Lebensmittel werden automatisch als „Verwenden“ markiert.
- Der Rezeptfinder kann persönliche Lieblingslebensmittel durchsuchen.
- Der bestehende Startfluss mit „Meine Rezepte“ und „Neues Rezept finden“ bleibt erhalten.

## Supabase Migration

Vor dem ersten Start von v31 die neue Migration `202609140001_onboarding_and_custom_foods.sql` im Supabase-Projekt ausführen.
