# Release v35

## Rezeptgenerator fertiggestellt

- Küche und vegetarische Option sind jetzt sichtbar im Rezept-Generator.
- Beide Einstellungen werden tatsächlich an die Edge Function übertragen.
- Die Edge Function berücksichtigt Küche, Vegetarisch, Personenzahl und maximale Zeit direkt im Prompt.
- Server validiert genau 3 Rezepte.
- Server validiert Personenzahl und erlaubte Zeitwerte.
- Vegetarische Antworten werden serverseitig zusätzlich gegen Fleisch- und Fisch-Kategorien geprüft.
- Nur als „Verwenden“ markierte Lebensmittel bleiben als zulässige Zutatenbasis erhalten.
- Versionsnummer auf `0.1.0+5` erhöht.

## Supabase

Nach dem lokalen Flutter-Test muss `supabase/functions/generate-recipes/index.ts` erneut als Edge Function `generate-recipes` deployed werden.
