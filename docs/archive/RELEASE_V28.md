# Release v28

## Neues App-Konzept

Die App ist jetzt bewusst auf den persönlichen Rezept-Workflow reduziert:

1. **Start**
   - Meine Rezepte
   - Neues Rezept finden

2. **Lebensmittel**
   - persönliche Lebensmittel auswählen und Vorlieben pflegen

3. **Meine Rezepte**
   - gespeicherte Rezepte ansehen

## Entfernt

- Haushalt
- Einladungen
- Essenswünsche
- Abstimmungen
- Wochenplanung
- Einkaufsliste
- Haushalt-/Sharing-Aktionen bei Rezepten

Die entsprechenden Flutter-Dateien und veralteten UI-Einstiege wurden entfernt.

Die bestehenden Supabase-Tabellen/Funktionen der früheren Haushaltsversion werden absichtlich noch nicht automatisch aus der Datenbank gelöscht. Das verhindert eine destruktive Migration, während die App bereits vollständig ohne das Haushaltskonzept funktioniert.
