# together – Release V93

## Persönliche Zusammenfassung nach der Hauptauswahl

V93 ersetzt die bisherige Drei-Karten-Zwischenseite nach der Auswahl in „Wir kochen“ durch eine persönliche Auswahlübersicht.

### Verhalten

- Die gewählte Hauptauswahl wird als Seitenüberschrift angezeigt.
- „Meine Wahl“ zeigt die Hauptauswahl mit einem passenden Symbol.
- Zusätzlich ausgewählte Lebensmittel werden darunter angezeigt.
- „Weitere Zutaten hinzufügen“ öffnet den bestehenden V92-Zutatenfluss mit Beilage, Gemüse und Favoriten.
- Ausgewählte Zutaten bleiben beim Zurückkehren erhalten.
- Die Anzahl ausgewählter Zusatz-Zutaten wird an der Box angezeigt.
- „Rezepte finden“ öffnet den bestehenden Rezept-Erstellen-Flow und übergibt die bereits ausgewählten Food-IDs.
- Rind, Schwein, Huhn, Fisch und Vegetarisch verwenden denselben dynamischen Flow.

## Technisch

- Keine Supabase-Migration erforderlich.
- `CookNextStepPage` ist nun ein Stateful-Selection-Summary.
- `AdditionalIngredientsPage` akzeptiert optional `mainChoice`.
- `RecipeBuilderPage` akzeptiert `initialSelectedFoodIds` und ein optionales `FoodRepository` für testbare Zustände.
- Hauptauswahl-Symbole werden zentral nach Auswahltyp zugeordnet.
- Lebensmittel-Symbole werden anhand des Namens für die Zusammenfassung zugeordnet.

## Tests

Neue Regressionstests prüfen:

- Überschrift und „Meine Wahl“ für Schwein.
- Gleiches Verhalten für Rind, Schwein, Huhn, Fisch und Vegetarisch.
- Navigation in den V92-Zutatenfluss.
- Rückgabe ausgewählter Zutaten in „Meine Wahl“.
- Übergabe vorhandener Zutaten an `RecipeBuilderPage`.

Version: `0.1.0+93`
