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

Stand dieses Dokuments: 2026-10-03

### GitHub

- `main` enthält die Restaurant-Discovery-Fallback-Reparatur und den anschließenden Photon-Parameter-Fix.
- Der Overpass-Fallback ist implementiert und durch Regressionstests geschützt.
- Die Photon-Vorwärtssuche verwendet keinen nicht unterstützten `radius=10`-Parameter mehr.
- Die aktuellen Regressionserwartungen wurden an das bestehende Verhalten angepasst.
- Der konkrete aktuelle `main`-Commit muss vor weiteren Änderungen erneut gelesen werden.

### CI

Der Quality-Gate-Workflow ist:

- `.github/workflows/flutter.yml`
- Trigger: Push auf `main`/ `develop` und Pull Requests
- Schritte:
  - Checkout
  - Flutter 3.47.2
  - Repository hygiene
  - `flutter pub get --enforce-lockfile`
  - `flutter analyze`
  - `flutter test`

Für den aktuellen Stand ist über die GitHub-Workflow-Run-Abfrage noch kein bestätigter Run verfügbar. Deshalb CI nicht als grün darstellen.

### Supabase

- Projekt: `oidxezjdwqktpxuypbfb`
- Edge Function: `restaurant-discovery`
- Live-Version: **38**
- Status: ACTIVE
- `verify_jwt=false`
- Import Map aktiv
- Die Funktion verwendet weiterhin eigene Authentifizierung über `supabase.auth.getUser(token)`.

Version 37 lieferte am 2026-10-03 wiederholt HTTP 503. Die Logs zeigten:

- Overpass: alle parallelen Endpunkte fehlgeschlagen.
- Photon: HTTP 400.
- Nominatim: HTTP 403.
- Danach 503 an den Client.

Die Photon-400-Ursache wurde identifiziert: Bei `/api` wurde `radius=10` gesendet. Photon unterstützt `radius` für `/reverse`, nicht für die Vorwärtssuche. Version 38 wurde mit diesem Fix deployed.

**Noch offen:** Nach dem Deploy ist noch kein neuer Restaurant-Discovery-Aufruf von Version 38 in den abgefragten aktuellen Logs sichtbar. Die tatsächliche Laufzeitwirkung ist daher noch nicht verifiziert.

## Restaurant Discovery – fachliche Regeln

Radius ist fest auf 10 km.

Aktuelle App-Kategorien:

- FoodMode.order: Pizza, Burger, Asiatisch, Döner, Sushi, Indisch, Überrasch mich
- FoodMode.dineOut: Italienisch, Steak, Asiatisch, Sushi, Burger, Mexikanisch, Vegetarisch, Überrasch mich

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

Dafür verwendet der aktuelle Code:

`cuisineSearchFallbackMatches(properties, cuisine)`

- Bei vorhandener passender Cuisine: strikter Cuisine-Match.
- Bei fehlendem Cuisine-Tag und kategorisiertem Photon/Nominatim-Ergebnis: providerbasierter Fallback.
- Der Restaurantname darf im Fallback **nicht** als Kategorie-Matcher verwendet werden.
- Overpass bleibt der bevorzugte, strikt gefilterte Pfad.
- Wenn Overpass null strikte Treffer liefert, wird Photon/Nominatim versucht.

## Nächster technischer Schritt

1. Einen echten Restaurant-Discovery-Aufruf mit Live-Version 38 auslösen.
2. Supabase-Logs prüfen:
   - wird Version 38 verwendet?
   - liefert Overpass Ergebnisse oder greift Photon?
   - ist der Photon-400 verschwunden?
   - ist der 503 verschwunden?
3. GitHub Actions für den aktuellen `main`-Stand prüfen.
4. Falls die Live-Suche weiterhin 503 liefert, Overpass-Verfügbarkeit und Nominatim-403 getrennt untersuchen.
5. Nach erfolgreicher Live-Prüfung und bestätigtem CI den Stand hier erneut aktualisieren.
6. Danach die nächsten offenen Repository-Aufgaben autonom aufnehmen.

## Sicherheits-/Arbeitsregeln

- Keine Secrets oder Service-Role-Keys in Chat, Code oder Logs ausgeben.
- Live-Systeme nicht als aktualisiert darstellen, solange die Version nicht verifiziert wurde.
- CI nicht als grün darstellen, solange der konkrete Commit nicht geprüft wurde.
- Bei neuen Änderungen zuerst den tatsächlichen Repository-Stand prüfen.
- Bestehende fachliche Regeln nicht durch eine scheinbar einfache, aber breitere Namenssuche umgehen.
- Änderungen möglichst in nachvollziehbaren Commits/PRs halten.
