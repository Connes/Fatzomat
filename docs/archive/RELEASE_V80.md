# V80 – Gemeinsame Einkaufsliste fertiggestellt

## Ziel
Die gemeinsame Einkaufsliste wird als klarer, alltagstauglicher Einkaufsflow ausgebaut. Offene Artikel stehen im Vordergrund, erledigte Artikel werden getrennt dargestellt und können gesammelt entfernt werden.

## Änderungen
- Offene und erledigte Artikel werden in getrennten Bereichen angezeigt.
- Kategorien bleiben innerhalb beider Bereiche erhalten.
- Erledigte Artikel können über „Leeren“ nach Bestätigung gesammelt gelöscht werden.
- Einzelnes Abhaken bleibt optimistisch und bei einem Fehler wird der vorherige Zustand wiederhergestellt.
- Einzelnes Hinzufügen, Bearbeiten und Löschen bleibt erhalten.
- Realtime-Synchronisation über `shopping_items` bleibt aktiv.
- Manuelle Artikel bleiben als solche gekennzeichnet.
- Die bestehende serverseitige Rezeptlisten-Erzeugung aus V79 wird nicht verändert.
- Keine neue Datenbankmigration erforderlich.
- Version auf `0.1.0+80` erhöht.

## Datenbank
V80 verwendet ausschließlich die bestehende Tabelle `shopping_items` und die bereits vorhandenen Repository-Operationen. Es wird kein Vorratsmanagement und keine automatische Rezeptänderung eingeführt.

## Verifikation
```bash
flutter analyze
flutter test
flutter build apk --debug
```

## Testpflege
- Den aus V79 übernommenen `v79_saved_recipe_action_test.dart` auf V80 aktualisiert, damit der bestehende Regressionstest weiterhin den gespeicherten-Rezept-Einkaufsflow prüft, aber korrekt die neue App-Version `0.1.0+80` erwartet.
