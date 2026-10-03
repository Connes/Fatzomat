# Fatzomat – Arbeitsübergabe

Dieses Dokument ist der dauerhafte Übergabepunkt zwischen Chat-Sitzungen.

## Arbeitsregel für neue Chats

Wenn der Nutzer in einem neuen Chat nur schreibt:

> Fatzomat weiterentwickeln.

dann gilt:

1. Dieses Dokument zuerst lesen.
2. Den beschriebenen Stand **immer gegen den tatsächlichen Stand von `main`** prüfen.
3. GitHub Actions/CI und, wenn relevant, den tatsächlichen Supabase-Stand prüfen.
4. Die offene Arbeit aus "Next step" autonom fortsetzen.
5. Nach Änderungen Tests/CI prüfen und den Stand weiterführen.
6. Vor einem späteren Chatwechsel dieses Dokument mit dem dann aktuellen tatsächlichen Stand aktualisieren.

Der Text in diesem Dokument ist ein Arbeitsgedächtnis, aber niemals Beweis für den Live-Zustand. Repository, CI und Supabase sind maßgeblich.

## Projekt

- Repository: `Connes/Fatzomat`
- Projektname: **Fatzomat**
- Hauptbranch: `main`
- App: Flutter
- Flutter in CI: 3.47.2 stable
- Sprache der Nutzerkommunikation: Deutsch
- Arbeitsweise: Änderungen möglichst autonom im Repository umsetzen, anschließend CI und relevante Live-Systeme prüfen.

## Aktueller Übergabestand

Stand dieses Dokuments: 2026-10-03

### GitHub

- `main` enthält die aktuellen Folge-Commits aus der laufenden Automatisierung.
- Der fünfminütige Watchdog liegt unter `.github/workflows/fatzomat-watchdog.yml`.
- Der Watchdog läuft alle 5 Minuten und prüft offene Pull Requests sowie die letzten GitHub-Actions-Läufe. Bei offenem Entwicklungsstand oder fehlgeschlagenen Läufen markiert er den Lauf als "Action needed"; bei sauberem Zustand dokumentiert er das im Workflow-Summary.
- PR #5 `fix: continue restaurant discovery after empty Overpass results` ist weiterhin offen. Durch neue Commits auf `main` muss sein Merge-Zustand erneut geprüft werden.

### CI

Der Quality-Gate-Workflow ist:

- `.github/workflows/flutter.yml`
- Trigger: Push auf `main`/`develop` und Pull Requests
- Schritte:
  - Checkout
  - Flutter 3.47.2
  - Repository hygiene
  - `flutter pub get --enforce-lockfile`
  - `flutter analyze`
  - `flutter test`

Zusätzlich läuft der neue Watchdog alle 5 Minuten. GitHub dokumentiert für geplante Actions ein Mindestintervall von 5 Minuten.

### Supabase

- Projekt: `oidxezjdwqktpxuypbfb`
- Edge Function: `restaurant-discovery`
- Zuletzt verifizierter Live-Stand: Version 36, ACTIVE, `verify_jwt=false`
- Die Funktion verwendet weiterhin eigene Authentifizierung über `supabase.auth.getUser(token)`.
- Der aktuelle PR-Stand ist noch nicht als live deployed bestätigt.

## Restaurant Discovery – fachliche Regeln

Radius ist fest auf 10 km.

Strikte Cuisine-Werte im Backend:

- Italienisch: italian
- Griechisch: greek
- Asiatisch: asian, chinese, thai, vietnamese, korean, indonesian, malaysian
- Indisch: indian
- Burger: burger
- Mexikanisch: mexican
- Vegetarisch: vegetarian bzw. passende diet-Tags
- Sushi: sushi
- Pizza: pizza, italian_pizza
- Döner: kebab, doner, döner
- Steak: steak, steak_house

Wichtige Regel: Nicht über Restaurantnamen oder breite Begriffe wie `grill`, `japanese`, `beef` usw. Kategorien erraten. Das hatte zu falschen Treffern geführt.

Mehrere echte Cuisine-Tokens wie `italian;pizza` dürfen mehrere Kategorien erfüllen.

### Restaurant-Fallback

Restaurants ohne OSM-`cuisine`-Tag sollen trotzdem gefunden werden können.

Dafür verwendet der aktuelle PR:

`cuisineSearchFallbackMatches(properties, cuisine)`

- Bei vorhandener passender Cuisine: strikter Cuisine-Match.
- Bei fehlendem Cuisine-Tag und kategorisiertem Photon/Nominatim-Ergebnis: providerbasierter Fallback.
- Der Restaurantname darf im Fallback **nicht** als Kategorie-Matcher verwendet werden.
- Overpass bleibt der bevorzugte, strikt gefilterte Pfad.
- Wenn Overpass null strikte Treffer liefert, wird nun Photon/Nominatim versucht.

### Nächster technischer Schritt

1. Aktuellen CI-Stand von PR #5 prüfen.
2. Falls nötig Branch gegen den aktuellen `main`-Stand aktualisieren bzw. die Änderungen sauber integrieren.
3. CI grün bekommen.
4. PR #5 integrieren.
5. Edge Function `restaurant-discovery` deployen und Live-Version verifizieren.
6. Danach den Restaurant-Fallback mit dem Live-System prüfen.
7. Weitere offene Aufgaben aus Repository und HANDOVER autonom fortsetzen.

## Automatisierung

Die ChatGPT-Aufgabe "Fatzomat weiterentwickeln" läuft weiterhin stündlich als übergeordnete Arbeitsprüfung.

Zusätzlich prüft GitHub Actions alle 5 Minuten den Repository-Zustand. Diese beiden Ebenen sind bewusst getrennt:

- GitHub: schneller technischer Wächter.
- ChatGPT: eigentliche Entwicklungsarbeit und Fehlerbehebung.

Der Watchdog nimmt keine riskanten automatischen Codeänderungen vor. Er erkennt offene Arbeit bzw. CI-Fehler und macht den Zustand im jeweiligen Actions-Lauf sichtbar. Für echte Codeänderungen bleibt eine Coding-Agent-Integration mit eigener GitHub/AI-Authentifizierung erforderlich.

## Sicherheits-/Arbeitsregeln

- Keine Secrets oder Service-Role-Keys in Chat, Code oder Logs ausgeben.
- Live-Systeme nicht als aktualisiert darstellen, solange die Version nicht verifiziert wurde.
- CI nicht als grün darstellen, solange der konkrete Commit nicht geprüft wurde.
- Bei neuen Änderungen zuerst den tatsächlichen Repository-Stand prüfen.
- Bestehende fachliche Regeln nicht durch eine scheinbar einfache, aber breitere Namenssuche umgehen.
- Änderungen möglichst in nachvollziehbaren Commits/PRs halten.
