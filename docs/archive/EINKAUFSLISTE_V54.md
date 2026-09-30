# V54 – Einkaufsliste 2.0

Die Einkaufsliste ist bewusst **manuell bearbeitbar**, nicht intelligent.

- Rezeptzutaten werden beim Planen für heute erzeugt.
- Nutzer können Artikel abhaken, hinzufügen, bearbeiten oder löschen.
- Menge und Einheit sind bei manuellen Artikeln optional. Intern werden bei fehlender Menge 1 und bei fehlender Einheit ein leerer Wert gespeichert, damit das bestehende Datenbankschema stabil bleibt.
- `source` unterscheidet Rezeptartikel (`recipe`) von manuellen Artikeln (`manual`).
- Bearbeitungen an der Einkaufsliste ändern niemals das Rezept.
- Realtime bleibt zwischen verbundenen Personen aktiv.
- Es gibt kein Vorratsmanagement und keine automatische Rezeptanpassung.

Nach Migration ausführen:

```bash
flutter analyze
flutter test
flutter build apk
```
