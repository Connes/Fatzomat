# together 1.5.0

## Neues Rezept hinzufügen

- Manuelles Erstellen eigener Rezepte
- Import von `together_recipe` JSON-Dateien, Version 1
- Import-Vorschau vor dem Speichern
- ChatGPT-Link ohne API-Anbindung oder OpenAI-Kosten
- Exportdarstellung des Rezeptmodells im selben `together_recipe` Format
- Tests für Import, Validierung und Exportformat

- Setup repariert: Bei einem veralteten Lockfile wird einmalig `flutter pub get` ausgeführt und danach erneut mit `--enforce-lockfile` geprüft.

- Bestehende Regressionstests wurden auf die neue App-Version `1.5.0+150` aktualisiert.


## V1.5.1

- Android: „Mit ChatGPT“ versucht zuerst, die installierte offizielle ChatGPT-App direkt zu öffnen.
- Falls die ChatGPT-App nicht installiert bzw. nicht startbar ist, bleibt der Browser-Fallback auf `https://chatgpt.com/` erhalten.
- Kein ChatGPT-/OpenAI-Login und keine API-Schlüssel werden von together verarbeitet.
- Das Android-Paket der offiziellen ChatGPT-App ist `com.openai.chatgpt`.
