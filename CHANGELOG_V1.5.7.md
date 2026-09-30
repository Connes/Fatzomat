# Schmackofatz V1.5.7

## Private Zwei-Personen-Version

- Rezeptgenerierung in Schmackofatz verwendet keine OpenAI-API mehr.
- „Wir kochen“ verwendet denselben externen ChatGPT-Workflow wie „Rezept hinzufügen“.
- Der erzeugte `together_recipe.json`-Import kann direkt aus dem ChatGPT-Workflow geöffnet werden.
- Entscheidungsanfragen beim Kochen werden erst nach dem Speichern des konkreten Rezepts aufgelöst.
- Der JSON-Dateizugriff wurde in eine kleine Plattformgrenze ausgelagert und nutzt `file_picker` 13.1.0 mit `readAsBytes()` und 1-MB-Limit.
- Einfache persönliche Datensicherung als `schmackofatz_backup.json` wurde ergänzt.
- Der künstliche 4-Sekunden-Launch-Splash wurde auf 900 ms reduziert.
- Private Release-APK-Builds benötigen keinen Produktions-Keystore mehr; ein eigener Keystore kann weiterhin verwendet werden.
- Die nicht mehr benötigten AI-Quota-RPCs sind für Client-Rollen gesperrt.
