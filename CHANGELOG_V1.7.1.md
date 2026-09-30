# Schmackofatz V1.7.1

## Zwei-Personen-Realtime: Stabilisierung

- Die Version wird auf `1.7.1+171` angehoben.
- Der Entscheidungsbildschirm gleicht seinen Zustand beim Zurückkehren aus dem Hintergrund erneut mit Supabase ab.
- Überlappende Realtime-/Lifecycle-Abfragen können keinen älteren Serverstand mehr über einen neueren Zustand schreiben.
- Beim Verlassen des Entscheidungsbildschirms werden Lifecycle-Beobachtung und offene Realtime-Aktualisierungen sauber invalidiert.
- Der bestehende `decision_requests`-Realtime-Kanal bleibt unverändert erhalten.
- Kein neuer Supabase-Migrationsbedarf.
- Kein OpenAI-API-Aufruf.

## Release

- Version: `1.7.1+171`
- Private Android-Version
