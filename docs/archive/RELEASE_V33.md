# Release v33

## Meine Rezepte erweitert

- Suchfeld für gespeicherte Rezepte
- Pull-to-refresh und manueller Aktualisieren-Button
- verständlichere Anzeige von Zeit, Portionen und Schwierigkeit
- Rezepte können gelöscht werden
- Löschen mit Bestätigungsdialog
- Rezeptdetail erlaubt weiterhin die Portionsskalierung
- Zutatenmengen werden sauber skaliert und formatiert
- Fehler beim Laden und Löschen werden sichtbar angezeigt

Keine neue Supabase-Migration erforderlich. Die vorhandene RLS-Policy erlaubt das Löschen eigener Rezepte; `recipe_ingredients` werden per `ON DELETE CASCADE` automatisch mit entfernt.
