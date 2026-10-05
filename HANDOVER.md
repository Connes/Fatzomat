# Fatzomat – Arbeitsübergabe

Dieses Dokument ist der dauerhafte Übergabepunkt zwischen Chat-Sitzungen.

## Arbeitsregel für neue Chats

Wenn der Nutzer in einem neuen Chat nur schreibt:

> Fatzomat weiterentwickeln.

dann gilt:

1. Dieses Dokument zuerst lesen.
2. Den beschriebenen Stand **immer gegen den tatsächlichen Stand von `main`** prüfen.
3. GitHub Actions/CI und, wenn relevant, den tatsächlichen Supabase-Stand prüfen.
4. Die offene Arbeit aus „Next step“ autonom fortsetzen.
5. Nach Änderungen Tests/CI prüfen und den Stand weiterführen.
6. Vor einem späteren Chatwechsel dieses Dokument mit dem dann aktuellen tatsächlichen Stand aktualisieren.

Der Text in diesem Dokument ist Arbeitsgedächtnis, aber niemals Beweis für den Live-Zustand. Repository, CI und Supabase sind maßgeblich.

## Projekt

- Repository: `Connes/Fatzomat`
- Projektname: **Fatzomat**
- Hauptbranch: `main`
- App: Flutter
- Flutter in CI: 3.47.2 stable
- Sprache der Nutzerkommunikation: Deutsch
- Arbeitsweise: Änderungen möglichst autonom im Repository umsetzen, anschließend CI und relevante Live-Systeme prüfen.

## Aktueller Übergabestand

Stand dieses Dokuments: 2026-10-05

### GitHub

- Aktueller `main`-Commit: `0c32da1f71a39a2985b4e9d7c596048cc0d8c699`
- Die jüngsten Änderungen betreffen vor allem Regressionstests und die aktuelle Recipe-/Food-Choice-UX.
- Der letzte Commit passt die Cooked-Recipe-Regression an die aktuelle Widget-Formatierung an.
- Der aktuelle Restaurant-Discovery-Code in `main` nutzt die Supabase-RPC-Funktion `search_restaurants` direkt über `SupabaseRestaurantDiscoveryRepository`.
- `restaurant-discovery` ist damit aktuell **nicht der von der App verwendete Live-Pfad**.
- Die Migration `20261004185400_restaurant_search_cuisine_expansion.sql` definiert `search_restaurants` mit 10-km-Radius, Cuisine-Token-Matching und optionalem Delivery-Filter.

### CI

Der Quality-Gate-Workflow ist:

- `.github/workflows/flutter.yml`
- Trigger: Push auf `main`/ `develop` und Pull Requests
- Schritte:
  - Checkout
  - Flutter 3.47.2
  - Repository hygiene
  - `flutter pub get --enforce-lockfile`
  - App-Icon-Generierung
  - `flutter analyze`
  - `flutter test`

Der Quality-Gate-Run #508 für `0c32da1f71a39a2985b4e9d7c596048cc0d8c699` läuft aktuell noch. Der vorherige Run #507 für den Handover-Commit `378ec884...` ist erfolgreich durchgelaufen.

### Supabase

- Projekt: `oidxezjdwqktpxuypbfb`
- Projektstatus: ACTIVE_HEALTHY
- Region: eu-central-1
- Edge Function: `restaurant-discovery`
- Live-Version: **42**
- Status: ACTIVE
- `verify_jwt=false`
- Import Map aktiv

Wichtig: Die App verwendet aktuell den RPC `search_restaurants`, nicht die Edge Function. In den aktuellen Logs vom 2026-10-05 sind wiederholt erfolgreiche Requests auf `/rest/v1/rpc/search_restaurants` mit HTTP 200 sichtbar. Für `restaurant-discovery` sind in den aktuellen Function-Logs keine Aufrufe sichtbar.

Ein direkter Live-SQL-Smoke-Test des RPCs mit einem neutralen Karlsruhe-Zentrum und `Pizza` lieferte mehrere Ergebnisse innerhalb von 10 km, einschließlich Distanz, Telefon, Website, Öffnungszeiten und Cuisine-Tags. Damit ist der aktuell von der App verwendete Restaurant-Suchpfad serverseitig funktionsfähig.

Supabase Performance Advisors wurden geprüft. Die vier gemeldeten unindizierten Foreign Keys in `decision_shares` wurden mit vier gezielten Indizes behoben. Die drei redundanten Owner-Policies auf `recipes` (DELETE/INSERT/UPDATE) wurden entfernt; die verbleibenden permissiven SELECT-/fachlichen Policies sind bewusst getrennt, weil sie unterschiedliche Zugriffswege abbilden. Der GIN-Index `restaurant_index_cuisine_gin` ist nicht ungenutzt: ein EXPLAIN des aktuellen Pizza-Suchmusters verwendet ihn zusammen mit dem Location-GiST-Index. Die übrigen `unused_index`-Hinweise bleiben vorerst Beobachtungen und werden wegen der kleinen Tabellen/fehlenden Nutzungsnachweise nicht blind entfernt.

## Restaurant Discovery – fachliche Regeln

Radius ist fest auf 10 km.

Der aktuelle Repository-/UI-Stand enthält inzwischen eine breitere Cuisine-Liste als die ältere Übergabe. Die aktuelle RPC-Migration unterstützt unter anderem:

- Italienisch: italian
- Griechisch: greek
- Türkisch: turkish
- Japanisch: japanese
- Chinesisch: chinese
- Thailändisch: thai
- Vietnamesisch: vietnamese
- Koreanisch: korean
- Indonesisch: indonesian
- Malaysisch: malaysian
- Indisch: indian
- Burger: burger
- Mexikanisch: mexican
- Spanisch: spanish
- Libanesisch: lebanese
- Portugiesisch: portuguese
- Vegetarisch: vegetarian
- Vegan: vegan
- Sushi: sushi
- Pizza: pizza, italian_pizza
- Döner: kebab, doner, döner
- Steak: steak, steak_house
- Asiatisch: asian, chinese, thai, vietnamese, korean, indonesian, malaysian

Mehrere echte Cuisine-Tokens wie `italian;pizza` dürfen mehrere Kategorien erfüllen.

### Aktueller Suchpfad

`lib/data/repositories/restaurant_discovery_repository.dart`:

- verlangt eine gültige persönliche Supabase-Sitzung;
- aktualisiert die Session vor der Suche;
- ruft `search_restaurants` als RPC auf;
- erzwingt im Repository einen 10-km-Radius;
- begrenzt Ergebnisse auf maximal 10;
- verwirft Antworten außerhalb von 10 km.

Die frühere Overpass/Photon/Nominatim-Fallback-Logik lebt weiterhin in der Edge Function `restaurant-discovery`, ist aber für den aktuellen App-Pfad nicht maßgeblich.

## Letzte verifizierte Live-Beobachtungen

- `search_restaurants`: aktuelle Requests HTTP 200.
- Direkter RPC-Test: erfolgreiche Ergebnisse im 10-km-Radius.
- `restaurant-discovery`: keine aktuellen Aufrufe in den abgefragten Function-Logs.
- Supabase-Projekt: ACTIVE_HEALTHY.
- CI: Run #508 für den aktuellen Commit läuft noch; Run #507 war erfolgreich.

## Nächster technischer Schritt

1. Den aktuellen Recipe-/Food-Choice-Stand weiter gegen die vorhandenen Regressionstests prüfen.
2. GitHub-CI-Status erneut prüfen, sobald ein Workflow-Run für den aktuellen `main`-Commit sichtbar ist.
3. Restaurant-Discovery nicht mehr primär über die alte Edge-Function untersuchen, solange die App den RPC verwendet.
4. Nach Abschluss von CI Run #508 den finalen Status prüfen und bei Erfolg den Handover entsprechend markieren.
5. Als nächstes sinnvolles Produkt-/Repository-Feature aus dem aktuellen `main`-Stand ableiten, statt die bereits funktionierende Restaurant-Suche erneut umzubauen.

## Sicherheits-/Arbeitsregeln

- Keine Secrets oder Service-Role-Keys in Chat, Code oder Logs ausgeben.
- Live-Systeme nicht als aktualisiert darstellen, solange die Version nicht verifiziert wurde.
- CI nicht als grün darstellen, solange der konkrete Commit nicht geprüft wurde.
- Bei neuen Änderungen zuerst den tatsächlichen Repository-Stand prüfen.
- Bestehende fachliche Regeln nicht durch eine scheinbar einfache, aber breitere Namenssuche umgehen.
- Änderungen möglichst in nachvollziehbaren Commits/PRs halten.
