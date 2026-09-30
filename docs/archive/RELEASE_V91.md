# together V91 – Zutaten-Auswahl mit Kategorien & Favoriten

## Umsetzung
- „Weitere Zutaten“ führt jetzt in eine eigene, klare Kategorienauswahl.
- Kategorien: **Beilage**, **Gemüse**, **Favoriten**.
- Beilage berücksichtigt die vorhandene Kategorie „Getreide & Beilagen“ sowie Kartoffelvarianten.
- Gemüse berücksichtigt die vorhandene Kategorie „Gemüse“ und hält Kartoffeln aus der Gemüseauswahl heraus.
- Favoriten nutzt die bestehende `user_food_preferences`-Logik mit `preference = like`; keine neue Datenbankstruktur nötig.
- Lebensmittel werden pro Kategorie als große, gut tappbare Auswahlzeilen mit Checkboxes dargestellt.
- Mehrfachauswahl bleibt über Kategoriewechsel hinweg erhalten.
- „Auswahl übernehmen“ gibt die IDs zurück in den bestehenden Rezept-Erstellungsfluss.
- Favoriten werden mit Herz-Visualisierung hervorgehoben.
- Fehler-, Leer- und Ladezustände sind berücksichtigt.
- Bestehendes Design-System und `TogetherScaffold` werden verwendet.
- App-Version auf `0.1.0+91` erhöht.

## Tests
- Neue Widget-Tests für Kategorien und Navigation zur Beilage-Auswahl.
- Bestehende Versionsprüfungen auf `+91` aktualisiert.

## Datenbank
Keine neue Migration erforderlich. Die bestehende Lebensmittelstruktur und `user_food_preferences` reichen für diese Funktion aus.
