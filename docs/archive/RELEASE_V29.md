# Release v29

## Vereinfachter Produktfluss

Der Startbildschirm hat nur noch zwei Hauptaktionen:

- **Meine Rezepte**: bisher gespeicherte Rezepte
- **Neues Rezept finden**: Lebensmittel auswählen und daraus mit ChatGPT neue Rezeptvorschläge erzeugen

Die Navigation enthält nur:

- Start
- Lebensmittel
- Meine Rezepte

## Haushalt vollständig aus der App entfernt

Entfernt wurden die Haushalts-, Einladungs-, Essenswunsch-, Abstimmungs-, Wochenplan- und Einkaufslistenbereiche sowie die entsprechenden Rezept-Aktionen.

Auch die letzte ungenutzte `household_context.dart`-Datei wurde entfernt.

Die alten Haushaltsobjekte in der Supabase-Datenbank werden weiterhin nicht automatisch gelöscht. Sie sind für die aktuelle App nicht mehr erreichbar. Eine destruktive Datenbankmigration wäre hier unnötig riskant.
