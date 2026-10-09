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

## Verbindlicher Entwicklungsworkflow

Der Nutzer beschreibt fachlich, was geändert werden soll. Danach wird die technische Umsetzung möglichst autonom erledigt, ohne dass der Nutzer jeden Git-/CI-Zwischenschritt einzeln anweisen muss.

1. Tatsächlichen Stand von `main`, offene PRs, relevante Tests und bei Bedarf Supabase prüfen.
2. Änderung implementieren, notwendige Tests ergänzen und Migrationen sauber versionieren.
3. Änderungen in nachvollziehbaren Commits und Pull Requests halten.
4. Relevante Qualitätsprüfungen ausführen: insbesondere Repository-Hygiene, `flutter analyze` und `flutter test`; passende weitere Prüfungen nach Bedarf.
5. Fehlgeschlagene Prüfungen untersuchen, beheben und erneut ausführen. Erfolg niemals behaupten, solange er nicht für den konkreten Stand bestätigt ist.
6. Pull Request mergen, sobald alle erforderlichen Prüfungen erfolgreich sind, die Änderungen fachlich korrekt sind und GitHub-Regeln dies zulassen. Wenn etwas blockiert, die konkrete Ursache benennen und soweit möglich selbst beheben.
7. Nach dem Merge den tatsächlichen Stand von `main` und die relevanten CI-Ergebnisse verifizieren.
8. Dem Nutzer den fertigen Stand knapp mitteilen. Der Nutzer führt lokal `git pull` aus und prüft die App auf seinem Gerät.

### Bewusste Projektgrenzen

- Fatzomat ist für den privaten Gebrauch des Nutzers gedacht. Das öffentliche GitHub-Repository bedeutet nicht, dass die App öffentlich verteilt werden soll.
- **Keine Release-Builds** im normalen Workflow erzeugen.
- **Keine Veröffentlichung oder Verteilung** der App einrichten oder durchführen.
- Debug-Builds und lokale Tests sind erlaubt, wenn sie für Entwicklung oder Fehlerdiagnose nützlich sind.
- Keine unnötige Release-/Store-Konfiguration ergänzen.
- Zusätzliche Berechtigungen nur dann anfordern, wenn ein konkreter Schritt mit dem vorhandenen Zugriff tatsächlich blockiert ist.
- Vor destruktiven Live-Datenbankänderungen oder risikoreichen Aktionen sorgfältig prüfen und bei wesentlichem Risiko vorher Rücksprache halten.
- Änderungen an Live-Systemen und Deployments separat verifizieren; ein GitHub-Merge beweist nicht automatisch, dass ein Live-System aktualisiert wurde.

## Projekt

- Repository: `Connes/Fatzomat`
- Hauptbranch: `main`
- App: Flutter
- Flutter in CI: 3.47.2 stable
- Sprache der Nutzerkommunikation: Deutsch
- Arbeitsweise: Änderungen möglichst autonom im Repository umsetzen, anschließend CI und relevante Live-Systeme prüfen.

## Aktueller Übergabestand

Stand dieses Dokuments: 2026-10-09 (Rezeptbild-Upload und Sitzungs-Refresh behoben)

### GitHub

- `main` enthält den Grafik-Commit `9dc4dd0`: die acht neuen Delivery-PNGs sind im Repository und die beiden alten Order-WebPs sind entfernt.
- PR #55 („Standardize food emojis and add missing produce“) wurde am 2026-10-09 gemergt. Merge-Commit: `9eb78ff8a1bb743a3a8a314b36fc33d432f9ffff`.
- Enthalten sind die Emoji-Korrekturen, Wassermelone 🍉, Kiwi 🥝 und Olive 🫒 sowie zugehörige Tests. Limette ist 🍋‍🟩, Rote Bete 🫜. Diese Änderungen sind in `main`.
- PR #56 („Allow unitless ingredients in imported recipes“) wurde am 2026-10-09 gemergt. Merge-Commit: `1007547a8a52f242f058f486529d7b9ce67801d4`.
- Fix: `create_shared_recipe` und `update_shared_recipe` erlauben nun leere Einheiten für Stück-Zutaten, z. B. „2 Zwiebeln“. Supabase-Migration `allow_unitless_recipe_ingredients` wurde auf Projekt `oidxezjdwqktpxuypbfb` angewendet und die Live-Funktionsdefinitionen verifiziert: Die Fehlermeldung „Eine Zutat benötigt eine Einheit.“ ist nicht mehr enthalten.

### CI

Der Quality-Gate-Workflow ist `.github/workflows/flutter.yml` mit Repository-Hygiene, `flutter pub get --enforce-lockfile`, Icon-Generierung, `flutter analyze` und `flutter test`. Für PR #55 waren beide Workflows erfolgreich. Für PR #56 waren `Quality Gate` (Analyze und Test) sowie `Flutter quality gate` (Hygiene, Dependencies, Icon-Generierung, Analyze und Test) auf dem korrigierten PR-Head erfolgreich. Die nach dem Merge gestarteten Workflows für Merge-Commit `1007547a8a52f242f058f486529d7b9ce67801d4` sowie den Handover-Commit `dde2e4e99a4f8494b3dd99c2e19316316e854ac7` sind inzwischen erfolgreich.

Es gibt außerdem `.github/workflows/build-apk.yml`, der manuell oder über einen `v*`-Tag läuft. Dieser Release-Build ist **nicht Teil des gewünschten Standardworkflows** und soll nicht automatisch ausgelöst oder erweitert werden.

### Supabase

- Projekt: `oidxezjdwqktpxuypbfb`
- Projektstatus bei letzter Prüfung: ACTIVE_HEALTHY
- Region: eu-central-1
- Edge Function `restaurant-discovery`: bei letzter dokumentierter Prüfung Version 42, ACTIVE, `verify_jwt=false`

Die App verwendet weiterhin den RPC `search_restaurants`, nicht die Edge Function.

### Restaurant Discovery

Der Radius ist fest auf 10 km. Der aktuelle App-Pfad ruft `search_restaurants` als RPC auf, verlangt eine gültige persönliche Session, aktualisiert die Session vor der Suche, begrenzt auf maximal 10 Ergebnisse und verwirft Ergebnisse außerhalb von 10 km.

## Aktuelle Fehleranalyse: Rezeptbild kann nicht hinzugefügt werden

- Relevante Implementierung: `lib/data/services/recipe_image_service.dart`, `lib/features/recipes/add_recipe_page.dart`, `lib/features/recipes/recipe_detail_page.dart` und `lib/data/repositories/recipe_repository.dart`.
- Live-Supabase-Prüfung am 2026-10-09: Bucket `recipe-images` existiert, ist privat, erlaubt JPEG/PNG/WebP und hat eine 10-MiB-Grenze.
- PR #57 und PR #58 waren nicht ausreichend. PR #59 wurde gemergt: eindeutige Bildpfade, `upsert: false` und eine bessere Klassifizierung von Storage-RLS-Fehlern.
- **Neue Live-Diagnose am 2026-10-09 nach PR #59:** Uploads auf eindeutige Pfade funktionieren nun mit HTTP 200 und `x_upsert=false`. Direkt danach scheitert `POST /object/sign/recipe-images/<recipe-id>/<dateiname>` mit `NoSuchKey` / „Object not found“. Die Zeile ist bereits in `storage.objects` vorhanden. Damit ist der Upload selbst erfolgreich; der Fehler tritt beim Erzeugen der Signed URL auf, bevor das Bild mit `recipes.image_path` verknüpft ist.
- Die SELECT-Policy für `recipe-images` lässt Objekte nur zu, wenn sie von einem Rezept referenziert werden. Die aktuelle Reihenfolge signiert zu früh, bevor `setRecipeImage` `recipes.image_path` aktualisiert. Der Storage-Endpunkt stellt dies als `NoSuchKey` dar und die App zeigt eine generische Fehlermeldung.
- **Fix in Arbeit:** Upload liefert nur noch den Storage-Pfad zurück. Der Repository-Ablauf verknüpft den Pfad zuerst mit dem Rezept; die Signed URL wird erst beim anschließenden Laden des Rezepts erzeugt. Regressionstest deckt die Reihenfolge ab. Danach CI prüfen und auf dem Gerät verifizieren.
- Keine Secrets, Tokens oder Service-Role-Keys protokollieren oder ausgeben.

## Sicherheits-/Arbeitsregeln

- Keine Secrets oder Service-Role-Keys ausgeben.
- Live-Systeme nicht als aktualisiert darstellen, solange die Version nicht verifiziert wurde.
- CI nicht als grün darstellen, solange der konkrete Commit nicht geprüft wurde.
- Bei neuen Änderungen zuerst den tatsächlichen Repository-Stand prüfen.
- Änderungen in nachvollziehbaren Commits/PRs halten.
- Niemals Release-Builds oder App-Veröffentlichung als Teil des Standardworkflows durchführen.
