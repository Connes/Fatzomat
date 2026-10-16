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


## Einkaufsliste: Tagesanzeige und Abschluss (2026-10-12)

- Tageskarten zeigen nur das Datum im Format `TT.MM.`; die Unterzeile mit Rezeptanzahl und Zutatenpositionen ist entfernt.
- Abgehakte Zutaten zeigen Zutatenname und Mengenangabe durchgestrichen und in zurückhaltender Textfarbe.
- Die Schaltfläche „Einkaufsliste erledigt“ löscht die Einkaufsartikel der aktuell ausgewählten aktiven Rezeptpläne. Nach dem Abschluss wird die Liste neu geladen; Fehler werden sichtbar gemeldet und der gespeicherte Zustand erneut geladen.
- Regressionstest ergänzt in `test/regression/shopping_list_active_plans_test.dart`.
- PR #76 wurde nach erfolgreichen Quality-Gate- und Flutter-quality-gate-Läufen für Head `82da34d2f1268270ba0d71facea044908700e88e` gemergt. Merge-Commit: `fea7e9c7a3afd288969a8b8223cb5140f0d10b9d`. Keine Release-Builds erstellen.


## Navigation nach Rezeptauswahl aus „Wir kochen“ (2026-10-12)

- `TodayPage` erhält den Tab-Wechsel-Callback aus `AppShell` und reicht eine explizite Navigation-zur-Heute-Seite-Callback-Kette über `FoodModePage`, `CookNextStepPage` bis `SavedRecipesPage` weiter.
- Wird ein gespeichertes Rezept aus „Wir kochen“ für den ausgewählten Tag übernommen, schaltet der AppShell-Navigator explizit auf den Heute-Tab und räumt die darüberliegenden Koch-Routen ab. So bleibt man nicht auf „Meine Rezepte“ hängen.
- Regressionstest: `test/regression/cook_saved_recipe_returns_to_today_test.dart`.
- PR-CI prüfen; keine Release-Builds erstellen.


## Navigation nach Rezeptauswahl: Routen explizit leeren (2026-10-12)

- Nach Rückmeldung aus der Nutzung wurde der Navigationspfad erneut geprüft: Der Callback allein war nicht ausreichend zuverlässig, um die aufgeschobenen Koch-Routen sichtbar zu verlassen.
- SavedRecipesPage leert im Koch-Flow jetzt explizit den aktuellen Navigator bis zur ersten Route und schaltet danach auf „Heute“.
- Regressionstest prüft jetzt auch das explizite Leeren des Navigationsstapels. PR-CI abwarten; keine Release-Builds erstellen.

## Rezeptbibliothek und belegte Planungstage (2026-10-12)

- Die Rezeptbibliothek soll nur Rezepte verwalten; der Abschnitt „Für dich heute“ wurde aus „Meine Rezepte“ entfernt.
- Jede Rezeptkarte bietet „Auswählen“. Die Auswahl öffnet einen Dialog mit den nächsten sieben Tagen.
- Bereits belegte Tage werden mit dem vorhandenen Rezept, „Wir gehen essen“ oder „Wir bestellen“ angezeigt und sind deaktiviert. Aktive gemeinsame Rezeptpläne werden ebenfalls als belegt berücksichtigt.
- Die Belegung wird vor Anzeige des Dialogs aus Supabase geladen. Fehler beim Laden blockieren die Auswahl, statt fälschlich freie Tage anzubieten.
- Die Rezeptauswahl verwendet für heute und zukünftige Tage die RPC set_personal_plan_for_date. Die Migration 20261012100000_prevent_overwriting_planned_days ergänzt eine serverseitige Konfliktprüfung mit Advisory Lock und verhindert, dass diese Auswahl bestehende persönliche oder gemeinsame Planungen still ersetzt.
- Bei Auswahl von heute navigiert die App wie bisher zurück zu „Heute“. Bei einem zukünftigen Datum bleibt sie in der Rezeptbibliothek und bestätigt das konkrete Datum, statt fälschlich „heute“ zu melden.
- Regressionstest: test/regression/recipe_date_picker_availability_test.dart.
- PR #79 („Add date-aware recipe selection and occupied-day protection“) wurde nach erfolgreichen Qualitätsprüfungen gemergt. Merge-Commit: 8332ae3f855f4d84a70d085a78f22a85cf1b0bbf.
- CI auf dem finalen PR-Head db5ac61e54ffb7305fdf2d3054c23684cad74b84 erfolgreich: Quality Gate Run 296 (Analyze und Test) sowie Flutter quality gate Run 935 (Repository-Hygiene, Dependencies, Icon-Generierung, Analyze und Test).
- Live-Supabase-Migration wurde angewendet und verifiziert. Die tatsächliche Migrationsversion in Supabase lautet 20261012083523 (`prevent_overwriting_planned_days`); die Funktionsdefinition enthält die Konfliktprüfung und Advisory Lock. `authenticated` darf die RPC ausführen, `anon` nicht.
- Nach dem Merge wurde der neue Auswahl-Dialog auf `main` verifiziert. Keine Release-Builds erstellt.

## Einkaufsliste: erledigte Tage ausblenden (2026-10-12)

- PR #80 („Hide completed shopping days and refresh selection count“) wurde nach erfolgreichem Flutter quality gate gemergt. Merge-Commit: bc7eb52ffec6678a0b067b8cd7b8df910b913882.
- Die sichtbaren Einkaufstage werden nun aus aktiven Rezeptplänen abgeleitet, für die noch mindestens ein Einkaufsartikel vorhanden ist. Sobald „Einkaufsliste erledigt“ die letzten Artikel eines Tages löscht, verschwindet auch dessen Datumsüberschrift.
- Nach dem Neuladen werden nicht mehr aktive Tage aus `_selected` und `_expanded` entfernt. Der Zähler „X von Y Tagen ausgewählt“ verwendet die aktualisierte Liste aktiver Tage.
- Regressionstest in `test/regression/shopping_list_active_plans_test.dart` ergänzt.
- Flutter quality gate Run 938 auf finalem PR-Head `2af0f6b9f087a8492eb083513c1501283f5f4753` erfolgreich: Repository-Hygiene, Dependencies, Icon-Generierung, Analyze und Test.
- Nach dem Merge wurde die neue Getter-Logik und der Regressionstest auf `main` verifiziert. Keine Release-Builds erstellt.



## Einkaufsliste: Abschluss erst nach Abhaken aller Zutaten (2026-10-12)

- PR #81 (Require all ingredients checked before completing shopping list) wurde nach erfolgreichen Qualitätsprüfungen gemergt. Squash-Merge-Commit: `3e9c691c8a0514e9b7967366fd7051a03c29cac9`.
- Die Schaltfläche „Einkaufsliste erledigt“ ist nur aktiv, wenn die zusammengefasste Einkaufsliste mindestens einen Eintrag hat und alle Einträge abgehakt sind.
- Die Abschlussmethode prüft dieselbe Bedingung zusätzlich, bevor Einkaufsartikel gelöscht werden. Bei offenen Zutaten erklärt ein Hinweis, warum der Abschluss noch nicht möglich ist.
- Regressionstest in `test/regression/shopping_list_active_plans_test.dart` ergänzt.
- CI auf PR-Head `d67c6ddcaed11d6a2b233ebd19eead4d84ced4ac` erfolgreich: Quality Gate Run 302 (Analyze und Test) sowie Flutter quality gate Run 941 (Repository-Hygiene, Dependencies, Icon-Generierung, Analyze und Test).
- Die Implementierung und der Regressionstest wurden nach dem Merge auf `main` verifiziert. Keine Release-Builds erstellt.


## Heute-Navigation: Rücksprung auf aktuelles Datum (2026-10-12)

- PR #83 („Reset the selected date when tapping Heute“) ergänzt ein explizites Reset-Signal von `AppShell` an `TodayPage`.
- Jeder Tipp auf den Heute-Tab setzt das ausgewählte Datum auf das aktuelle lokale Datum zurück und lädt den Tagesplan dafür neu, auch wenn der Heute-Tab bereits ausgewählt ist.
- Die bestehende Navigation mit Tagespfeilen und Wischgesten bleibt erhalten.
- Regressionstest: `test/regression/today_tab_resets_date_test.dart`.
- CI und Post-Merge-Stand nach dem Merge verifizieren. Keine Supabase-Änderungen und keine Release-Builds.

 
## Lieferdienste: Bestellabschluss bestätigen (2026-10-12)

- Die Schaltfläche auf der Lieferdienste-Seite heißt „Bestellung abschließen?“.
- Ein Tipp öffnet zuerst einen Bestätigungsdialog mit „Bestellung abschließen?“ sowie „Abbrechen“ und „Bestellung abschließen“. Der Bestellstatus wird nur nach ausdrücklicher Bestätigung geändert.
- Regressionstest: `test/regression/delivery_order_confirmation_test.dart`.
- Keine Supabase-Änderung und keine Release-Builds.


## Willkommensüberschrift im Lebensmittel-Onboarding (2026-10-12)

- Die Überschrift lautet „Willkommen“ ohne Ausrufezeichen und ist zentriert.
- Regressionstest in `test/regression/food_onboarding_intro_visual_test.dart` aktualisiert.
- Keine Änderung am weiteren Onboarding-Ablauf, keine Supabase-Änderung und kein Release-Build.

## Lesbarkeit der Seite „Gemeinsam nutzen“ (2026-10-12)

- Die Erklärung „Optional zu zweit“ und die Steuerelemente zum Erstellen oder Eingeben eines Verbindungscodes liegen auf undurchsichtigen weißen Karten statt direkt auf dem dekorativen Hintergrund.
- Die bestehende Karte für den Verbindungsstatus bleibt erhalten; Geschäftslogik und Verbindungsablauf sind unverändert.
- Regressionstest in `test/regression/connection_personal_first_readiness_test.dart` ergänzt.
- Keine Supabase-Änderung und keine Release-Builds.


## Datumsbezogenes Teilen von Entscheidungen (2026-10-12)

- Fehlerursache: `send_decision_message` las immer den Plan mit `plan_date = current_date`, obwohl die Heute-Seite auch zukünftige ausgewählte Tage darstellt. Dadurch verglich der RPC die falsche Entscheidung und meldete „Deine heutige Entscheidung hat sich geändert“.
- Die App übergibt nun die ID des tatsächlich angezeigten Plans. Die neue Migration `20261012140000_date_aware_decision_sharing` validiert diesen Plan serverseitig und speichert das korrekte Plan-Datum in der Freigabe.
- Eingehende Freigaben werden für das ausgewählte Datum geladen. Übernehmen erstellt die persönliche und gemeinsame Planung für genau dieses Datum; Ablehnen funktioniert ebenfalls für zukünftige Tage. Vergangene Freigaben können nicht mehr übernommen werden.
- Regressionstest: `test/regression/date_aware_decision_sharing_test.dart`.
- Migration ist für PR/CI vorbereitet und muss nach erfolgreichem Merge auf Supabase angewendet und live verifiziert werden. Keine Release-Builds.


## Navigation zu geteilten Entscheidungen (2026-10-12)

- Beim Öffnen einer Entscheidungsbenachrichtigung wird nun die zugehörige `decision_shares.plan_date` geladen und `TodayPage(initialDate: ...)` mit diesem Datum geöffnet.
- Dieselbe Datumsnavigation gilt für Push-Notifications bei App-Start, App im Hintergrund und lokale Benachrichtigungen. Falls eine alte Benachrichtigung keine Share-ID mehr hat oder die Freigabe nicht mehr lesbar ist, bleibt der Fallback auf Heute erhalten.
- Regressionstest in `test/regression/decision_message_sharing_test.dart` prüft beide Navigationspfade.
- Keine Datenbankänderung nötig; wartet auf CI und Merge. Keine Release-Builds.


## Navigationsleiste bei Push-Rückmeldungen zu Entscheidungen (2026-10-12)

- Ursache: Der Push-Handler öffnete `TodayPage` direkt über den globalen Root-Navigator. Dadurch wurde `AppShell` samt unterer Navigation vollständig überdeckt.
- Push-Taps auf geteilte Entscheidungen öffnen jetzt `AppShell(initialDate: targetDate)`. `AppShell` reicht das Ziel-Datum an `TodayPage` weiter; damit bleiben die untere Navigationsleiste und die richtige Tagesauswahl erhalten.
- Regressionstests prüfen den Push-Zielpfad und die Datumsweitergabe in `AppShell`.
- PR und CI ausstehend. Keine Supabase-Änderung und keine Release-Builds.


## Bestätigungsdialog beim Entfernen von Entscheidungen (2026-10-12)

- Der Hinweis auf persönliche Rezeptartikel und die Einkaufsliste erscheint beim Entfernen nur noch für echte Rezeptentscheidungen (`plan.isRecipe`).
- Bei „Wir bestellen“, „Wir gehen essen“ und anderen Nicht-Rezept-Entscheidungen enthält der Dialog nur noch die Information, dass die Entscheidung aus dem Plan entfernt wird.
- Regressionstest in `test/regression/personal_today_decision_types_test.dart` ergänzt.
- PR/CI ausstehend. Keine Supabase-Änderung und keine Release-Builds.


## Restaurantdetail: einheitliche Kontaktkarte (2026-10-12)

- Anschrift, Telefon, Webseite und Öffnungszeiten werden für jedes Restaurant immer angezeigt, in einer gemeinsamen Karte mit getrennten Bereichen und feinen Trennlinien.
- Fehlt ein Feld in den gelieferten Daten, steht in diesem Bereich „Nicht verfügbar“, statt den gesamten Bereich auszublenden.
- Telefonnummer und Webseite bleiben antippbar, sofern vorhanden. Bestelllink und Lieferstatus werden bei Bedarf ebenfalls innerhalb derselben Karte dargestellt.
- Regressionstests in `test/regression/restaurant_discovery_test.dart` decken vollständige und fehlende Kontaktdaten ab.
- PR/CI ausstehend. Keine Supabase-Änderung und keine Release-Builds.


## Eingehende geteilte Entscheidung: fokussierte Ansicht (2026-10-12)

- Bei einer ausstehenden geteilten Entscheidung zeigt die Tagesansicht ausschließlich die Annahme-/Ablehnungskarte; die normalen Entscheidungsbereiche und erledigten Entscheidungen bleiben bis zur Aktion ausgeblendet.
- Überschrift zeigt den Anzeigenamen der verbundenen Person, sofern verfügbar. Für „Wir gehen essen“ wird der Restaurantname darunter gezeigt; Typ- und Personenzahl-Zusatz entfallen.
- Nach Übernehmen/Ablehnen wird neu geladen und die normale Tagesansicht erscheint wieder.
- CI/PR ausstehend; keine Supabase-Änderungen und keine Release-Builds.


## Restaurantentscheidung abschließen (2026-10-12)

- Wird die Restaurantdetailseite aus einer bereits ausgewählten Tagesentscheidung geöffnet, erscheint unten „Entscheidung abschließen“.
- Die Aktion entfernt die Tagesentscheidung, aktualisiert Rezept-Markierungen und kehrt zur Tagesansicht zurück.
- Normale Restaurantdetails behalten „Für heute auswählen“.
- CI/PR ausstehend; keine Supabase-Änderungen und keine Release-Builds.


## Letzte Änderung: Navigation zwischen offenen Entscheidungen

- Heute-Seite: Doppelpfeil rechts springt zum nächsten Datum mit einer aktiven persönlichen Entscheidung (Status `planned`); Tage ohne offene Entscheidung werden übersprungen.
- Auf zukünftigen Tagen erscheint zusätzlich ein Doppelpfeil links. Er springt zur vorherigen offenen Entscheidung, aber niemals vor Heute; wenn keine frühere offene Entscheidung existiert, führt er zurück zu Heute.
- Einfache Pfeile und Wisch-Navigation bleiben unverändert.
- Regressionstest ergänzt. CI muss nach dem PR noch bestätigt werden.


## Kompakte Datumsleiste (2026-10-12)

- Datumsformat auf `Mo, 12. Oktober` umgestellt: zweibuchstabige deutsche Wochentagskürzel, ausgeschriebener Monatsname.
- Navigation in der App-Leiste angeordnet: Doppelpfeile außen, einfache Tagespfeile innen; Touch-Flächen auf 40 px Breite reduziert, um mehr Platz für das Datum zu schaffen.
- Regressionstest für das Datumsformat ergänzt. PR/CI ausstehend; keine Release-Builds.


## Datumsnavigation zentrieren (2026-10-12)

- Die Datumsanzeige ist unabhängig von den Navigationspfeilen exakt mittig ausgerichtet.
- In der Heute-Ansicht werden beide Rückwärts-Pfeile ausgeblendet. Auf zukünftigen Tagen erscheinen sie links; die Vorwärts-Pfeile bleiben rechts.
- Regressionstest für die zentrierte Anzeige und die bedingten Rückwärts-Steuerelemente ergänzt.
- PR/CI ausstehend. Keine Release-Builds.

## Gemeinsame Entscheidungsabschlüsse synchronisieren (2026-10-12)

- Neue Migration `20261012160000_sync_shared_decision_completion.sql`: Wenn eine akzeptierte geteilte Entscheidung auf einem Gerät auf `cooked` gesetzt wird, setzt ein Datenbank-Trigger auch die verknüpfte persönliche Kopie des Partners auf `cooked`.
- Die Änderung läuft serverseitig und löst dadurch auf beiden Geräten die vorhandene Realtime-Aktualisierung der persönlichen Tagespläne aus. Der Trigger ist idempotent.
- Regressionstest für die Trigger-/Migrationserwartungen ergänzt.
- PR/CI ausstehend. Die Migration muss nach dem Merge separat in Supabase angewendet und dort verifiziert werden. Keine Release-Builds.


## Gemeinsame Entscheidungen: Löschung synchronisieren (2026-10-13)

- Die bisherige Migration synchronisiert nur den Abschlussstatus `cooked`; sie synchronisiert keine Löschungen.
- Neue Migration `20261013153000_sync_shared_decision_deletion.sql`: Ein `BEFORE DELETE`-Trigger auf `personal_today_plans` sucht nur aktive, angenommene Freigaben mit beiden Plan-IDs, markiert die Verknüpfung vorab als storniert und löscht die verknüpfte persönliche Kopie serverseitig. Der zweite Triggerlauf findet dadurch keine aktive Freigabe mehr. Private Pläne, offene Einladungen und bereits stornierte Freigaben lösen keine Gegenlöschung aus.
- Regressionstest: `test/regression/shared_decision_deletion_sync_test.dart`.
- PR und CI ausstehend. Die Migration muss nach erfolgreichem PR-Review in Supabase angewendet und die tatsächliche Triggerdefinition live geprüft werden. Keine Release-Builds.


## Verbindung bei Trennung beidseitig auflösen (2026-10-13)

- Live-Prüfung: `disconnect_connection()` entfernte bislang nur den aufrufenden Eintrag aus `connection_members`. Die `connections`-Zeile blieb bestehen, solange der andere Mitgliedseintrag existierte. Daher zeigte die Gegenseite weiter eine Verbindung mit nur einem Mitglied an.
- Neue Migration `20261013170000_disconnect_connection_for_both_members.sql`: `disconnect_connection()` löscht die Verbindung selbst, nachdem geprüft wurde, dass der Aufrufer Mitglied ist. Fremdschlüssel entfernen beide Mitgliedseinträge innerhalb derselben Transaktion.
- Zusätzlicher `AFTER DELETE`-Trigger bereinigt verwaiste Verbindungen, wenn ein Mitglied über `auth.users ON DELETE CASCADE` gelöscht wird. Fällt die Mitgliedszahl unter zwei, wird die Verbindung einschließlich des verbleibenden Mitglieds entfernt. Persönliche Pläne, Rezepte und Favoriten werden durch diese Migration nicht gelöscht.
- Regressionstest: `test/regression/connection_disconnect_both_members_test.dart`.
- Wichtig: Eine reine App-Deinstallation sendet kein Ereignis an den Server und kann nicht unmittelbar erkannt werden. Die serverseitige Bereinigung greift bei tatsächlicher Kontolöschung oder expliziter Trennung.
- PR/CI und Live-Migration ausstehend. Keine Release-Builds.


## „Entscheide Du“ für das ausgewählte Datum (2026-10-13)

- Fehlerursache: `_askPartnerToDecide()` sendete nur `type: 'ask'`; die Supabase-RPC setzte `decision_shares.plan_date` und den Push-Text deshalb immer auf `current_date`.
- Die App übergibt nun `_selectedDate`. Die RPC nimmt `p_plan_date` entgegen, lehnt vergangene Tage serverseitig ab und verwendet das Datum sowohl für `decision_shares.plan_date` als auch für den Benachrichtigungstext. Damit führt der Push-Tap über die vorhandene Share-ID-/planDate-Navigation zum ausgewählten Tag.
- Zwei bestehende Regressionstests wurden an den neuen Aufruf angepasst; der neue Datums-Regressionsfall bleibt enthalten.
- PR #101 am 2026-10-13 gemergt: `a38d3326c3e20a5845ed7f5f06049250c1c168e3`. Beide PR-Quality-Gates waren erfolgreich (Analyze und Tests).
- Supabase-Migration `date_aware_decide_for_me` auf Projekt `oidxezjdwqktpxuypbfb` angewendet. Live verifiziert: Die Funktion `send_decision_message(..., p_plan_date date)` ist vorhanden und ihre Definition nutzt das übergebene Datum für `decision_shares.plan_date` sowie den Benachrichtigungstext.
- Keine Release-Builds.

## Surprise-Roulette: CI-Regressions behoben (2026-10-15)

- PR #148 („Fix CI after removing obsolete surprise flow“) wurde gemergt. Merge-Commit auf `main`: `4db0c894d3101bd185d1c3384a93f548a7d94540`.
- `lib/features/shared/today_page.dart`: fünf ungenutzte Imports entfernt, die nach dem Entfernen des veralteten direkten Surprise-Flows übrig geblieben waren.
- `test/regression/personal_today_decision_types_test.dart`: veraltete Erwartung an `_openSurprise()` auf den aktuellen `_handleSurprise()`-/`SurpriseModeRoulettePage`-Navigationspfad angepasst.
- PR-CI erfolgreich. Nach dem Merge wurden Quality Gate Run `38798110581` und Flutter quality gate Run `38798110602` auf `main` ebenfalls mit `success` abgeschlossen.
- Keine Supabase-Migration, kein Release-Build und keine Veröffentlichung erforderlich.
- Aktueller nächster Schritt: bei der nächsten Änderung den tatsächlichen Stand von `main` und die dazugehörige CI prüfen; keine offenen Arbeiten aus dieser Fehlerbehebung.

## Surprise-Roulette: Casino-Walzen mit Kategorie-Bildern (2026-10-16)

- Ausgangspunkt: `SurpriseModeRoulettePage` nutzte Timer-getaktete Indexsprünge und `AnimatedSwitcher`; das wirkte wie Gezuckel statt einer echten, gleichmäßigen Walzenbewegung.
- Neue Umsetzung auf Branch `feature/casino-image-roulette`: drei unabhängig laufende Walzen mit den vorhandenen Kategorie-Assets `icon_cooking.png`, `icon_delivery.png` und `icon_restaurant.png`. Die Bilder bewegen sich frame-synchron per `AnimationController`/Ticker; beim Stoppen bremsen die Walzen nacheinander mit `Curves.easeOutQuart` ab und landen alle auf derselben zufällig gewählten Kategorie.
- Optik: dunkelrote Casino-Maschine, goldener Rahmen/Payline, drei Reel-Fenster, Stopptaste und hervorgehobenes Gewinnerbild. Keine neue Dependency und keine neuen Bilddateien nötig.
- Animationstechnik an offizieller Flutter-Dokumentation ausgerichtet: explizite Controller für koordinierte, wiederholte Bewegung; Animationen auf kleine Widget-Teilbäume begrenzt. Quellen: https://api.flutter.dev/flutter/animation/AnimationController-class.html und https://docs.flutter.dev/perf/best-practices
- Regressionstest ergänzt: `test/regression/surprise_roulette_animation_test.dart`.
- PR #149 wurde per Squash-Merge integriert; Merge-Commit auf `main`: `834c4d43ef05e43535e7593b83a9ba733adb86e5`.
- Beide PR-Qualitätsprüfungen auf Head `207e75f7b25563301f31651957c11ab35c57f225` erfolgreich: Quality Gate Run `38852756446` und Flutter quality gate Run `38852756469` (Hygiene, Dependencies, Icon-Generierung, Analyze und Tests).
- Post-Merge-Workflows auf dem Merge-Commit sind gestartet und müssen abschließend geprüft werden.
- Keine Supabase-Migration und keine Release-Builds.

## Surprise-Roulette: Feinschliff nach Nutzerfeedback (2026-10-16)

- PR #150 („Polish surprise roulette header and repeat button“) wurde gemergt. Merge-Commit: `7f5bf71528271da0ae69026944d874cd7256166a`.
- Den oberen Introblock inklusive „DER ZUFALL HAT ENTSCHIEDEN“ und „Euer Abend steht fest.“ entfernt; dadurch steht die Casino-Walzenbox weiter oben.
- Laufband-Überschrift zwischen den Sternen auf `FATZOMA` geändert.
- „NOCHMAL DREHEN“ ist jetzt ein ausgefüllter dunkelroter Button mit goldener Schrift, Icon und Goldrahmen für klaren Kontrast auf dem Hintergrund.
- Regressionstest für Branding, entfernte Texte und Button-Kontrast ergänzt.
- PR-CI erfolgreich: Quality Gate Run `38853957458` und Flutter quality gate Run `38853957448`, beide mit Analyze und Tests erfolgreich.
- Post-Merge-CI und Handover-Commit-CI nach der Dokumentation noch prüfen. Keine Supabase-Migration und kein Release-Build.


## Surprise-Roulette: Markenname korrigiert (2026-10-16)

- Nutzerkorrektur: Die Beschriftung zwischen den Sternen lautet `FATZOMAT`, nicht `FATZOMA`.
- Roulette-Label und Regressionstest entsprechend angepasst. Keine weitere UI-Änderung, keine Supabase-Migration und kein Release-Build.
- CI-Prüfungen für PR und nach dem Merge stehen noch aus.


## Surprise-Roulette: gemeinsamer Stopp und passende Gewinnerkarte (2026-10-16)

- Die drei Walzen stoppen weiterhin sichtbar nacheinander, aber mit stark verkürzten Bremsphasen. Die gesamte Stoppreihenfolge ist auf maximal rund 900 ms ausgelegt.
- Unter „EURE GEWINNER-KATEGORIE“ bleibt nur das Kategorie-Bild sichtbar; der zusätzliche Text „Wir essen“/„Wir bestellen“/„Wir kochen“ darunter wurde entfernt.
- Die Gewinnerkarte verwendet jetzt denselben dunkelroten Verlauf, goldenen Rahmen und abgerundeten Casino-Stil wie die Slotmaschine.
- Regressionstest auf sequenzielles Stoppen innerhalb einer Sekunde und das Gewinnerkarten-Layout angepasst.
- PR-CI und Post-Merge-CI stehen aus. Keine Supabase-Änderung und kein Release-Build.
