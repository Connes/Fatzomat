# Schmackofatz V1.6.1

## Backend-/Client-Konsistenz

- Live-Supabase auf den aktuellen Flutter-Vertrag synchronisiert.
- Decision Requests, Notifications und die zugehörigen RPCs ergänzt bzw. gehärtet.
- `shared_recipe_plans.servings` und Shopping-Quellen (`recipe` / `manual`) ergänzt.
- Realtime für Connection Members, Decision Requests und Notifications geprüft und fehlende Tabellen ergänzt.
- Alter 4-Argument-Resolver bleibt historisch erhalten, ist aber für Client-Rollen nicht mehr ausführbar.

## Heute

- `TodayPage` verwendet den vorhandenen `TodayController` jetzt korrekt und synchronisiert dessen Lade-, Fehler- und Datenzustand.
- Controller wird sauber initialisiert und beim Verlassen des Screens freigegeben.

## Fehlerbehandlung

- Zentrale benutzerfreundliche Fehlertexte statt roher Exception-Ausgaben in den wichtigsten Entscheidungs- und Überraschungsflows.

## Version

- App-Version: `1.6.1+161`
- Android-Launchername bleibt `Fatzomat`.
- Produktname innerhalb der App bleibt `Schmackofatz`.
