# Release v34

## Rezeptqualität

Der Flow für „Neues Rezept finden“ wurde um echte Rezeptvorgaben ergänzt:

- Auswahl der Küche
- vegetarische Option
- Personenzahl und Kochzeit bleiben Teil der Generierung
- KI-Prompt enthält explizite Regeln für ausgewählte Lebensmittel
- Lebensmittel mit `dislike` dürfen nicht verwendet werden
- zusätzliche Zutaten sind erlaubt, aber nur sinnvoll und nachvollziehbar
- genau 3 unterschiedliche Rezeptvorschläge

Die bestehenden strukturierten JSON-Ausgaben und die serverseitige OpenAI-Nutzung bleiben erhalten.

## Wichtig

Nach dem lokalen Flutter-Test muss die aktualisierte Edge Function `generate-recipes` in Supabase deployed werden, damit die neuen Prompt-Regeln produktiv greifen.
