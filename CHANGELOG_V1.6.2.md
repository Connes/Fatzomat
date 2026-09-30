# Schmackofatz V1.6.2

## Schwerpunkt
Single-Device-Kernworkflow stabilisiert und „Heute“ als zentralen Einstieg für den Tagesablauf geschärft.

## Änderungen

- Versionsstand auf `1.6.2+162` angehoben.
- `Heute` erhält bei leerem Tagesplan direkte Aktionen für gespeicherte Rezepte und die ChatGPT-Rezepterstellung.
- Nach dem Statuswechsel auf „Einkaufen“ öffnet `Heute` die zugehörige Einkaufsliste direkt.
- Einkaufsliste: fehlerhafte Übernahme des `TodayController` aus dem Today-Screen entfernt.
- Einkaufsliste: Realtime-Subscription wird direkt auf den aktuellen Tagesplan gefiltert.
- Rezeptdetail: Nach „Für uns heute festlegen“ kann direkt zu `Heute` gewechselt werden.
- Bestehender Supabase-Reconciliation-Stand aus V1.6.1 bleibt unverändert.
- Der Zwei-Personen-Runtime-Test bleibt bewusst späteren Versionen vorbehalten.

## Nicht enthalten

- Keine OpenAI-API und keine kostenpflichtige serverseitige Rezeptgenerierung.
- Keine Änderung am privaten Zwei-Personen-Produktumfang.
- Keine Migration historischer Supabase-Migrationen.
