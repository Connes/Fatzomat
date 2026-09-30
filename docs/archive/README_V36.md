# Food App MVP v36

Die Startseite ist jetzt direkt die Rezeptsuche.

- Hauptzutat: Rind, Schwein, Huhn, Fisch oder Vegetarisch
- Weitere Lebensmittel werden aus der persönlichen Lebensmittelliste gewählt
- Gewürze und Saucen werden nicht in der Auswahl angezeigt
- Rezepte werden direkt von der Startseite aus generiert
- Keine Personen-, Zeit- oder Küchen-Auswahl auf der Startseite
- Aktuelle interne Standardwerte: 2 Personen, 45 Minuten, Küche „Egal“

## Supabase

Die Edge Function `generate-recipes` muss die v36-Version enthalten. Sie verwendet zusätzlich Gewürze/Saucen/Grundzutaten als erlaubte Basiszutaten, sofern diese nicht als Dislike markiert sind.
