# V81 – Heute-Plan bearbeiten und synchronisieren

## Ziel
Der gemeinsame Tagesplan ist nicht mehr nur ein Endpunkt. Rezept, Personenzahl und heutiger Plan können direkt aus „Heute“ verwaltet werden, während die Einkaufsliste serverseitig synchron bleibt.

## Änderungen
- Der Tagesplan zeigt jetzt die gewählte Personenzahl und, falls vorhanden, die Rezeptbeschreibung.
- Das Rezept kann direkt aus „Heute“ geöffnet werden.
- Die Personenzahl kann nachträglich von 1 bis 12 geändert werden.
- Beim Ändern der Personenzahl werden die automatisch aus dem Rezept erzeugten Einkaufsposten serverseitig neu skaliert.
- Manuell hinzugefügte Einkaufsposten bleiben bei der Synchronisierung erhalten.
- Ein heutiges Rezept kann entfernt werden. Der Plan wird dabei auf `cancelled` gesetzt.
- Ein heutiges Rezept kann durch ein anderes gespeichertes Rezept ersetzt werden. Die Ersetzung erfolgt atomar über einen serverseitigen RPC-Flow.
- Realtime-Aktualisierung des Tagesplans und der Einkaufsliste bleibt bestehen.
- Version auf `0.1.0+81` erhöht.

## Datenbank
Neue Migration: `supabase/migrations/202609160001_v81_today_plan_editing.sql`

- `shared_recipe_plans.servings` speichert die für den heutigen Plan gewählte Personenzahl.
- Bestehende Pläne werden bei der Migration mit der Rezept-Personenzahl initialisiert.
- Neue RPCs: `update_shared_recipe_plan_servings`, `cancel_shared_recipe_plan`, `replace_shared_recipe_plan`.
- `share_recipe_for_today` wird so aktualisiert, dass die gewählte Personenzahl auch im Tagesplan gespeichert wird.

## Synchronisationsregel
Beim Ändern der Personenzahl werden ausschließlich `source = 'recipe'`-Artikel neu aufgebaut. Manuelle Artikel bleiben unverändert. Dadurch wird der Rezeptanteil der Einkaufsliste korrekt neu skaliert, ohne persönliche Ergänzungen zu zerstören.

## Absichtlich nicht geändert
- Keine neue Haushalts-/Verbindungslogik.
- Keine Änderung am bestehenden Entscheidungsanfrage-Statusmodell.
- Keine Änderung an den freigegebenen Startseiten-Assets.
