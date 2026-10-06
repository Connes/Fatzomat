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
- Hauptbranch: `main`
- App: Flutter
- Flutter in CI: 3.47.2 stable
- Sprache der Nutzerkommunikation: Deutsch
- Arbeitsweise: Änderungen möglichst autonom im Repository umsetzen, anschließend CI und relevante Live-Systeme prüfen.

## Aktueller Übergabestand

Stand dieses Dokuments: 2026-10-06

### GitHub

- Aktueller `main`-Commit vor Handover-Update: `974619cd2de84a14ec2562a5ea038edbd456eeec`
- PR #38 wurde gemergt: Die Today-Seite zeigt die gewählte Bestellart und öffnet die Lieferdienst-Auswahl.
- PR #39 wurde gemergt: `public.recipe_fingerprint(jsonb,jsonb)` verwendet nun explizit `search_path=pg_catalog`.
- Die zugehörige Migration ist `supabase/migrations/20261006205000_harden_recipe_fingerprint_search_path.sql`.

### CI

Der Quality-Gate-Workflow ist `.github/workflows/flutter.yml` mit Repository-Hygiene, `flutter pub get --enforce-lockfile`, Icon-Generierung, `flutter analyze` und `flutter test`.

PR #39 hatte Quality-Gate-Run #591. Der PR wurde erfolgreich gemergt. Der abschließende Workflow-Status war beim Check zeitlich noch nicht vollständig aus dem Actions-Feed verfügbar; für den neuen Main-Commit ist CI daher noch separat zu verifizieren.

### Supabase

- Projekt: `oidxezjdwqktpxuypbfb`
- Projektstatus: ACTIVE_HEALTHY
- Region: eu-central-1
- Edge Function `restaurant-discovery`: Version 42, ACTIVE, `verify_jwt=false`

Die App verwendet weiterhin den RPC `search_restaurants`, nicht die Edge Function.

Der Security Advisor meldet nach der Härtung keinen `function_search_path_mutable`-Befund mehr für `recipe_fingerprint`. Verifiziert wurde `proconfig=["search_path=pg_catalog"]` und ein erfolgreicher Fingerprint-Smoke-Test.

Verbleibende Security-Warnungen betreffen u.a. `pg_net` in `public`, bewusst eingesetzte `SECURITY DEFINER`-RPCs und bestehende Anonymous-Auth/RLS-Policies. Diese werden nicht blind entfernt.

## Restaurant Discovery

Der Radius ist fest auf 10 km. Der aktuelle App-Pfad ruft `search_restaurants` als RPC auf, verlangt eine gültige persönliche Session, aktualisiert die Session vor der Suche, begrenzt auf maximal 10 Ergebnisse und verwirft Ergebnisse außerhalb von 10 km.

Die RPC unterstützt die inzwischen erweiterte Cuisine-Taxonomie einschließlich italienisch, griechisch, türkisch, japanisch, chinesisch, thailändisch, vietnamesisch, koreanisch, indonesisch, malaysisch, indisch, Burger, mexikanisch, spanisch, libanesisch, portugiesisch, vegetarisch, vegan, Sushi, Pizza, Döner, Steak und asiatisch.

## Nächster technischer Schritt

1. CI für den neuen `main`-Commit prüfen.
2. Recipe-/Food-Choice-Stand gegen die vorhandenen Regressionstests prüfen.
3. Restaurant-Discovery nicht erneut über die alte Edge Function umbauen, solange die App den RPC verwendet.
4. Danach das nächste sinnvolle Produkt-/Repository-Feature aus dem aktuellen `main`-Stand ableiten.

## Sicherheits-/Arbeitsregeln

- Keine Secrets oder Service-Role-Keys ausgeben.
- Live-Systeme nicht als aktualisiert darstellen, solange die Version nicht verifiziert wurde.
- CI nicht als grün darstellen, solange der konkrete Commit nicht geprüft wurde.
- Bei neuen Änderungen zuerst den tatsächlichen Repository-Stand prüfen.
- Änderungen in nachvollziehbaren Commits/PRs halten.
