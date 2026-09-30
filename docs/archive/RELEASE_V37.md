# Release v37

## Startseite

- „Mahlzeit“ aus der AppBar entfernt.
- Den unteren Bereich „Meine Rezepte / Gespeicherte Rezepte öffnen“ von der Startseite entfernt.
- Startseite auf eine reine Rezeptauswahl reduziert.
- Neue visuelle Kartenansicht für Rind, Schwein, Huhn, Fisch, Vegetarisch und Überrasch mich.
- Responsive Darstellung für kleinere und größere Smartphone-Displays.
- Die vorhandene Navigation zu Lebensmittel und Meine Rezepte bleibt bestehen.
- „Überrasch mich“ wählt weiterhin clientseitig zufällig eine der fünf Hauptausrichtungen.

## Supabase

Keine Datenbank- oder Edge-Function-Änderung erforderlich. Die bestehende v3-Funktion `generate-recipes` unterstützt die Startseiten-Auswahl bereits.
