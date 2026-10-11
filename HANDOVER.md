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

Stand dieses Dokuments: 2026-10-11 (mehrtägige Planung, Navigation und Datumsauswahl korrigiert; PR #71 gemergt)

### GitHub

- `main` enthält den Grafik-Commit `9dc4dd0`: die acht neuen Delivery-PNGs sind im Repository und die beiden alten Order-WebPs sind entfernt.
- PR #55 („Standardize food emojis and add missing produce“) wurde am 2026-10-09 gemergt. Merge-Commit: `9eb78ff8a1bb743a3a8a314b36fc33d432f9ffff`.
- Enthalten sind die Emoji-Korrekturen, Wassermelone 🍉, Kiwi 🥝 und Olive 🫒 sowie zugehörige Tests. Limette ist 🍋‍🟩, Rote Bete 🫜. Diese Änderungen sind in `main`.
- PR #56 („Allow unitless ingredients in imported recipes“) wurde am 2026-10-09 gemergt. Merge-Commit: `1007547a8a52f242f058f486529d7b9ce67801d4`.
- PR #70 („Add date-aware meal planning foundation“) wurde am 2026-10-10 gemergt. Merge-Commit: `3aefbf2b38b617af6c38220a299b4cb61bda7d86`. Enthalten: datumsbezogene persönliche Planung, Navigation über mehrere Tage, aggregierte Einkaufsliste für drei Tage, Portionen-RPC, Schutz vor Offline-Datumsverwechslung und Regressionstests.
- Fix: `create_shared_recipe` und `update_shared_recipe` erlauben nun leere Einheiten für Stück-Zutaten, z. B. „2 Zwiebeln“. Supabase-Migration `allow_unitless_recipe_ingredients` wurde auf Projekt `oidxezjdwqktpxuypbfb` angewendet und die Live-Funktionsdefinitionen verifiziert: Die Fehlermeldung „Eine Zutat benötigt eine Einheit.“ ist nicht mehr enthalten.

### CI

Der Quality-Gate-Workflow ist `.github/workflows/flutter.yml` mit Repository-Hygiene, `flutter pub get --enforce-lockfile`, Icon-Generierung, `flutter analyze` und `flutter test`. Für PR #55 waren beide Workflows erfolgreich. Für PR #56 waren `Quality Gate` (Analyze und Test) sowie `Flutter quality gate` (Hygiene, Dependencies, Icon-Generierung, Analyze und Test) auf dem korrigierten PR-Head erfolgreich. Für PR #70 waren `Quality Gate` (Run 243) und `Flutter quality gate` (Run 882) auf dem finalen PR-Head `1d1206067f9749d98969f3e32d546923f50dfd56` erfolgreich; beide Prüfungen umfassten Analyze und Tests, der Flutter-Gate zusätzlich Hygiene, Dependencies und Icon-Generierung. Die nach dem Merge gestarteten Workflows für Merge-Commit `1007547a8a52f242f058f486529d7b9ce67801d4` sowie den Handover-Commit `dde2e4e99a4f8494b3dd99c2e19316316e854ac7` sind inzwischen erfolgreich.

Es gibt außerdem `.github/workflows/build-apk.yml`, der manuell oder über einen `v*`-Tag läuft. Dieser Release-Build ist **nicht Teil des gewünschten Standardworkflows** und soll nicht automatisch ausgelöst oder erweitert werden.

### Supabase

- Projekt: `oidxezjdwqktpxuypbfb`
- Projektstatus bei letzter Prüfung: ACTIVE_HEALTHY
- Region: eu-central-1
- Edge Function `restaurant-discovery`: bei letzter dokumentierter Prüfung Version 42, ACTIVE, `verify_jwt=false`

Die App verwendet weiterhin den RPC `search_restaurants`, nicht die Edge Function.
- Am 2026-10-10 wurden die Migrationen `date_aware_personal_planning` und `update_personal_plan_servings` erfolgreich angewendet. Live-Migrationsstände: `20261010095423` und `20261010095430`.
- Live-Funktionsprüfung bestätigt: `get_personal_plans_for_date` läuft als `SECURITY INVOKER`; die beiden schreibenden RPCs haben festen `search_path` und sind für `authenticated` ausführbar, nicht für `anon`. Migrationen sind damit auf Supabase aktiv.

### Restaurant Discovery

Der Radius ist fest auf 10 km. Der aktuelle App-Pfad ruft `search_restaurants` als RPC auf, verlangt eine gültige persönliche Session, aktualisiert die Session vor der Suche, begrenzt auf maximal 10 Ergebnisse und verwirft Ergebnisse außerhalb von 10 km.

## Aktuelle Fehleranalyse: Rezeptbild kann nicht hinzugefügt werden

- Relevante Implementierung: `lib/data/services/recipe_image_service.dart`, `lib/features/recipes/add_recipe_page.dart`, `lib/features/recipes/recipe_detail_page.dart` und `lib/data/repositories/recipe_repository.dart`.
- Live-Supabase-Prüfung am 2026-10-09: Bucket `recipe-images` existiert, ist privat, erlaubt JPEG/PNG/WebP und hat eine 10-MiB-Grenze.
- PR #57 und PR #58 waren nicht ausreichend. PR #59 wurde gemergt: eindeutige Bildpfade, `upsert: false` und eine bessere Klassifizierung von Storage-RLS-Fehlern.
- **Neue Live-Diagnose am 2026-10-09 nach PR #59:** Uploads auf eindeutige Pfade funktionieren nun mit HTTP 200 und `x_upsert=false`. Direkt danach scheitert `POST /object/sign/recipe-images/<recipe-id>/<dateiname>` mit `NoSuchKey` / „Object not found“. Die Zeile ist bereits in `storage.objects` vorhanden. Damit ist der Upload selbst erfolgreich; der Fehler tritt beim Erzeugen der Signed URL auf, bevor das Bild mit `recipes.image_path` verknüpft ist.
- Die SELECT-Policy für `recipe-images` lässt Objekte nur zu, wenn sie von einem Rezept referenziert werden. Die aktuelle Reihenfolge signiert zu früh, bevor `setRecipeImage` `recipes.image_path` aktualisiert. Der Storage-Endpunkt stellt dies als `NoSuchKey` dar und die App zeigt eine generische Fehlermeldung.
- **Implementierungsstatus laut aktuellem `main` erneut prüfen:** Der zuletzt dokumentierte Fix sollte den Storage-Pfad zuerst mit dem Rezept verknüpfen und die Signed URL erst danach erzeugen. Noch keine aktuelle Geräteverifikation dokumentiert.
- Keine Secrets, Tokens oder Service-Role-Keys protokollieren oder ausgeben.

## Mehrtägige Planung: Navigations- und Datumskorrektur (2026-10-11)

- PR #71 („Fix future-day planning navigation and recipe selection“) wurde nach erfolgreichen Qualitätsprüfungen gemergt. Squash-Merge-Commit: `b1e331ce0994e1ca994c61d71b34aca7f5e6f054`.
- `TodayPage` beginnt heute; Initialdaten aus der Vergangenheit werden auf heute begrenzt. Zurück-Navigation ist heute deaktiviert, und Pfeile/Wischgesten können nicht in die Vergangenheit führen.
- Horizontale Wischgesten funktionieren über den Hauptinhalt. Die App-Leiste zeigt das ausgewählte Datum.
- Gespeicherte Rezepte laden den persönlichen Plan für das ausgewählte Datum und geben dieses Datum an beide Rezeptdetail-Navigationspfade weiter. Die Restaurant-Discovery erhält nun ebenfalls `planDate`, sodass Entscheidungen für den richtigen Tag gespeichert werden.
- Regressionstests decken Datumssperre, Wischgesten, Datumstransport und Datumsanzeige ab. Ein bestehender Test wurde an den neuen datumsabhängigen Auswahltext angepasst.
- CI auf PR-Head `6b95c2d9d4ac536d6151e3200d999e9358331e00` erfolgreich: Quality Gate Run 248 / Test und Analyze erfolgreich; Flutter quality gate Run 888 / Hygiene, Dependencies, Icon-Generierung, Analyze und Test erfolgreich.
- Keine Supabase-Migration erforderlich. Nach dem Merge muss der tatsächliche `main`-Stand und die Merge-CI noch verifiziert werden.

## App-Bar-Datumsnavigation und Seitenwechsel (2026-10-11)

- PR #72 („Move day navigation to app bar and animate swipes“) wurde per Squash-Merge in `main` integriert. Merge-Commit: `976410bc2931f686adba090dda0a9101ba17f29d`.
- Die Tagesnavigation befindet sich jetzt in der oberen App-Bar-Zeile. Der Pfeil für den vorherigen Tag wird nur angezeigt, wenn nicht „Heute“ ausgewählt ist; der Pfeil für den nächsten Tag bleibt sichtbar.
- Beim Datumswechsel bleibt der bisherige Inhalt sichtbar, während der Plan für das Zieldatum geladen wird. Danach gleitet die bisherige Seite aus dem Blick und die neue Seite gleitet aus der Gegenrichtung hinein.
- Regressionstest aktualisiert, um die Position der Navigation und den Slide-Übergang abzusichern.
- **CI-Status:** Der erste Push-Workflow fand einen fehlenden schließenden Klammerausdruck in `today_page.dart`; der Fehler wurde korrigiert. Auf dem aktuellen `main`-Commit `03b35f68e715bf2998435bdab3d331b5db99684a` sind Repository-Hygiene, Dependencies und Icon-Generierung erfolgreich; `flutter analyze` ist erfolgreich. `flutter test` läuft noch (Runs 38159962826 und 38159963032). Nachgelagerte CI abschließend prüfen.
- Keine Supabase-Änderung und kein Release-Build.

## Korrektur der datumsbezogenen Planlöschung und Rezeptnavigation (2026-10-11)

- PR #73 („Fix date-aware plan removal and recipe selection navigation“) wurde nach erfolgreichen PR-Qualitätsprüfungen gemergt. Merge-Commit: `dfcac9256b081ab24ac2c1fe6db634ad012f27fc`.
- Ursache 1: Beim Wechsel des ausgewählten Datums blieb der vorherige Plan während des Ladevorgangs interaktiv. `TodayPage` blendet jetzt den Inhalt aus, bis der Plan für das Ziel-Datum geladen ist.
- Ursache 2: `cancel_personal_today_plan` beschränkte das Update auf `plan_date = current_date` und löschte Einkaufsartikel vor der Prüfung, ob ein Plan aktualisiert wurde. Die neue Funktion aktualisiert den eigenen aktiven Plan per ID und löscht Einkaufsartikel erst nach erfolgreicher Aktualisierung.
- Die Migration `date_aware_plan_cancellation` wurde auf Supabase-Projekt `oidxezjdwqktpxuypbfb` angewendet. Die Live-Funktionsdefinition wurde mit `pg_get_functiondef` geprüft.
- Nach dem Festlegen eines gespeicherten Rezepts navigiert die Rezepte-Tab-Auswahl jetzt zu „Heute“. Bei einer verschachtelten Rezeptsuche im Kochablauf wird der Erfolg an die Elternrouten zurückgegeben, die dann zu „Heute“ zurückkehren.
- Regressionstests ergänzt/angepasst. PR-CI auf Head `e924c15b2c05bb2f02f7f5d374f50fbb0bafa642` erfolgreich: Quality Gate Run 38161623620 und Flutter quality gate Run 38161623583.
- Post-Merge-CI für Merge-Commit `dfcac9256b081ab24ac2c1fe6db634ad012f27fc` bei Erstellung dieses Eintrags noch abschließend prüfen. Keine Release-Builds erstellt.

## Schutz vor vorzeitigem Abschluss zukünftiger Entscheidungen (2026-10-11)

- Der Abschlussstatus einer Entscheidung entspricht in der Datenbank `status = 'cooked'`. Die bestehende RPC `update_personal_today_status` akzeptiert bereits nur Pläne mit `plan_date = current_date`; diese serverseitige Datumsprüfung bleibt bestehen.
- Zusätzlich prüft `RecipeDetailPage.markCooked()` das ausgewählte Datum ausdrücklich, bevor es den Status ändern darf. Es lädt den Plan außerdem mit `widget.planDate`, statt bei einem Datumswechsel versehentlich den heutigen Plan zu lesen.
- Neue Supabase-Migration `prevent_future_plan_completion` ergänzt einen Datenbank-Trigger, der `status = 'cooked'` für ein zukünftiges `plan_date` bei INSERT und UPDATE abweist. Damit ist der Schutz nicht von der Sichtbarkeit eines Buttons oder einem einzelnen Client-Pfad abhängig.
- Regressionstest `test/regression/future_decision_completion_guard_test.dart` prüft UI-Guard, datumsbezogenes Laden und Datenbank-Trigger.
- Live-Migration wurde auf Supabase-Projekt `oidxezjdwqktpxuypbfb` angewendet (Version `20261011180842`, `prevent_future_plan_completion`). Die Triggerdefinition wurde live geprüft; `tgenabled = 'O'` bestätigt, dass der Trigger aktiviert ist.
- Nach dem Merge die CI auf dem endgültigen `main`-Commit verifizieren. Keine Release-Builds erstellen.

## Sicherheits-/Arbeitsregeln

- Keine Secrets oder Service-Role-Keys ausgeben.
- Live-Systeme nicht als aktualisiert darstellen, solange die Version nicht verifiziert wurde.
- CI nicht als grün darstellen, solange der konkrete Commit nicht geprüft wurde.
- Bei neuen Änderungen zuerst den tatsächlichen Repository-Stand prüfen.
- Änderungen in nachvollziehbaren Commits/PRs halten.
- Niemals Release-Builds oder App-Veröffentlichung als Teil des Standardworkflows durchführen.


## Einkaufsliste: aktive Pläne und Lesbarkeit (2026-10-11)

- Die Mehrtages-Einkaufsliste zeigt ausschließlich Tage mit mindestens einer aktiven Rezeptentscheidung; leere Tage und reine Nicht-Rezept-Entscheidungen werden nicht als Einkaufsliste angeboten.
- Die Auswahl wird auf Tage mit tatsächlich vorhandenen Rezeptplänen beschränkt. Wenn kein aktives Rezept im Dreitagesfenster existiert, erscheint ein klarer leerer Zustand.
- Die Zutaten-Suchleiste wurde entfernt. Die Filterung nach offenen Zutaten und das Abhaken mehrerer Einträge bleiben erhalten.
- Tageseinträge und Zutatenbereiche verwenden deckende, helle Flächen mit kontrastreicher Textfarbe, damit der Hintergrund die Lesbarkeit nicht beeinträchtigt.
- Die Migration `cleanup_cancelled_plan_shopping_items` entfernt Einkaufsartikel zuverlässig bei jeder Stornierung oder Löschung eines persönlichen Plans, unabhängig vom Datum; sie bereinigt auch zuvor zurückgebliebene Artikel stornierter Pläne.
- Regressionstest: `test/regression/shopping_list_active_plans_test.dart`.
- PR #75 („Show only active shopping lists and improve readability“) wurde nach erfolgreichen PR-Prüfungen gemergt. Squash-Merge-Commit: `3383ba7f99f7a3e49777af456a9712d937649445`.
- CI auf dem finalen PR-Head `38c19f7c4cdc93979fa60663b7fa0761a62acde3` erfolgreich: Quality Gate Run 274 sowie Flutter quality gate Run 913; Analyze und Test waren erfolgreich.
- Live-Supabase-Migrationen auf Projekt `oidxezjdwqktpxuypbfb`: `cleanup_cancelled_plan_shopping_items` Version `20261011181919` und `restrict_cleanup_trigger_function` Version `20261011182135`.
- Trigger `cleanup_personal_plan_shopping_items` ist aktiviert (`tgenabled = 'O'`). Er entfernt Einkaufsartikel bei Statuswechsel auf `cancelled` und bei direkter Planlöschung. Bereinigung alter stornierter Pläne abgeschlossen: 0 zurückgebliebene Einkaufsartikel.
- Funktion ist nicht als RPC für `anon` oder `authenticated` ausführbar. Die Rechte wurden live geprüft.
- Der Post-Merge-CI-Status auf dem exakten Merge-Commit war über die GitHub-Schnittstelle bei Prüfung noch nicht sichtbar. Keine Release-Builds erstellen.
