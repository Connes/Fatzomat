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

- `main` enthält aktuell Commit `8e1f829fae73cdab325099aff22c1f502b5fade9`.
- Dieser Commit entstand durch das gemergte PR #4:
  `fix: find restaurants without OSM cuisine tags (#4)`.
- Die Restaurant-Discovery-Änderungen sind damit auf `main`, aber der Live-Supabase-Stand ist davon noch nicht vollständig aktualisiert.

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

Für den aktuellen Commit `8e1f829` war beim letzten Check noch kein bestätigter Workflow-Status verfügbar. Deshalb nicht als grün annehmen.

Ein älterer CI-Lauf hatte drei inzwischen als veraltet bekannte Regressionserwartungen:
- `recipe_detail_compact_test.dart`
- `shopping_list_completion_test.dart`
- `decision_share_once_per_day_test.dart`

Vor einer weiteren Änderung zuerst den aktuellen CI-Stand prüfen, statt alte Fehler blind zu reparieren.

### Supabase

- Projekt: `oidxezjdwqktpxuypbfb`
- Edge Function: `restaurant-discovery`
- Live-Version beim letzten Check: **36**
- Status: ACTIVE
- `verify_jwt=false`
- Import Map aktiv
- Die Funktion verwendet weiterhin eigene Authentifizierung über `supabase.auth.getUser(token)`.

Wichtig: Der Code auf `main` mit dem neuen Fallback ist noch nicht zuverlässig als Live-Version bestätigt.

Ein Deploymentversuch über das Supabase-Tool scheiterte an der Import-Map/`deno.json`-Auflösung. Vor einem neuen Deploy zuerst aktuelle Supabase-Dokumentation/Tool-Unterstützung prüfen und danach den Live-Stand verifizieren. Niemals den Service-Role-Key offenlegen.

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

Wichtige Regel: Nicht wieder über Restaurantnamen oder breite Begriffe wie `grill`, `japanese`, `beef` usw. Kategorien erraten. Das hatte zu falschen Treffern geführt.

Mehrere echte Cuisine-Tokens wie `italian;pizza` dürfen mehrere Kategorien erfüllen.

### Aktuelles offenes Problem

Restaurants ohne OSM-`cuisine`-Tag sollen trotzdem gefunden werden können.

Dafür wurde eingeführt:

`cuisineSearchFallbackMatches(properties, cuisine)`

- Bei vorhandener passender Cuisine: `cuisine_tag`
- Bei fehlendem Cuisine-Tag und kategorisiertem Photon/Nominatim-Ergebnis: `provider_category_fallback`
- Der Restaurantname darf im Fallback **nicht** wieder als Kategorie-Matcher verwendet werden.

Photon und Nominatim verwenden den neuen Fallback bereits.

**Technische Lücke:** Der Overpass-Pfad filtert weiterhin direkt nach `cuisine` und gibt auch bei null Treffern sofort ein leeres Payload zurück. Dadurch wird der Photon/Nominatim-Fallback in diesem Fall nicht erreicht.

### Nächster technischer Schritt

Die sichere, wenig invasive Lösung ist:

1. Overpass weiterhin streng lassen.
2. Nur dann das Overpass-Payload zurückgeben, wenn `results.length > 0`.
3. Bei null Overpass-Treffern mit Photon/Nominatim fortfahren.
4. Einen Regressionstest hinzufügen, der genau diesen Fallback-Pfad schützt.
5. CI ausführen.
6. Danach die Edge Function sauber deployen und die Live-Version verifizieren.
7. Erst dann den Stand hier als erledigt markieren.

## Bereits wichtige Produktänderungen

- Recipe Detail: vereinfachter Abschlussfluss.
- Gekochte Today-Pläne sind abgeschlossen und nicht mehr teilbar/entfernbar/erneut zu öffnen.
- Zutaten und Zubereitung sind ExpansionTiles und zunächst geschlossen.
- Rezeptschritte sind nur für den aktiven Today-Plan sequential abschließbar.
- Einkaufsliste wird beim serverseitigen Übergang auf `cooked` geleert.
- Abschlusszustand der Einkaufsliste wurde getestet.

## Sicherheits-/Arbeitsregeln

- Keine Secrets oder Service-Role-Keys in Chat, Code oder Logs ausgeben.
- Live-Systeme nicht als aktualisiert darstellen, solange die Version nicht verifiziert wurde.
- CI nicht als grün darstellen, solange der konkrete Commit nicht geprüft wurde.
- Bei neuen Änderungen zuerst den tatsächlichen Repository-Stand prüfen.
- Bestehende fachliche Regeln nicht durch eine scheinbar einfache, aber breitere Namenssuche umgehen.
- Änderungen möglichst in nachvollziehbaren Commits/PRs halten.

## Übergabeprotokoll für den nächsten Chat

Wenn ein Chat wegen Kontextlänge endet, soll der nächste Chat nur den Satz

**„Fatzomat weiterentwickeln.“**

benötigen.

Dann dieses Dokument lesen, den tatsächlichen Stand prüfen und bei "Next step" weitermachen. Nach Abschluss oder vor dem nächsten Übergabepunkt dieses Dokument aktualisieren, damit der aktuelle Arbeitsstand erhalten bleibt.
