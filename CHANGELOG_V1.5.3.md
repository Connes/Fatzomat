# V1.5.5 – Stabilerer JSON-Import

- Version `1.5.5+155`.
- JSON-Rezeptdateien werden beim Auswählen nicht mehr per `withData` vollständig vom nativen Picker in den Speicher geladen.
- Der Import nutzt stattdessen den Dateistream und fällt bei Bedarf auf den lokalen Pfad zurück. Das ist robuster für Android-Dokument-Provider wie Downloads und Cloud-Dateien.
- Ungültige UTF-8-Dateien werden als Importfehler angezeigt statt den Importfluss zu beenden.

# Schmackofatz V1.5.3

## ChatGPT-Dateiworkflow und Rezeptimport

- Der ChatGPT-Prompt fordert jetzt ausdrücklich eine echte, herunterladbare Datei `together_recipe.json`.
- Die Datei wird für den direkten Import in Schmackofatz mit `together_recipe` Version 1 strukturiert.
- Die Hauptauswahl wird als zwingende Rezeptbasis behandelt; ausgewählte Zutaten müssen verwendet werden.
- „Rezeptdatei importieren“ erkennt und validiert die Datei, zeigt vor dem Speichern eine übersichtliche Vorschau und speichert das Rezept anschließend über das bestehende `RecipeRepository`.
- Nach erfolgreichem Import wird bestätigt, dass das Rezept in „Meine Rezepte“ gespeichert wurde.
- Importierte Rezepte verwenden dieselbe `Recipe`-Struktur und dieselbe Detailansicht wie andere gespeicherte Rezepte.
- Keine OpenAI-API und kein zusätzliches API-Budget erforderlich.
