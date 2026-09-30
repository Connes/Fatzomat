# Schmackofatz V1.9.0

## Rezeptworkflow

- Rezepte können aus der Rezeptdetailansicht wieder als `together_recipe.json` exportiert werden.
- Der Export verwendet weiterhin exakt das stabile `together_recipe`-Format Version 1.
- Beim Export werden die aktuell gewählten Portionen berücksichtigt, sodass die gespeicherte Datei zu den angezeigten Mengen passt.
- Dateinamen werden aus dem Rezeptnamen sicher erzeugt.
- Der bestehende ChatGPT-Importworkflow bleibt unverändert und kann exportierte Rezeptdateien wieder einlesen.
- Keine OpenAI-API und keine neue Supabase-Migration.

## Release

- Version: `1.9.0+190`
- Private Android-Version
