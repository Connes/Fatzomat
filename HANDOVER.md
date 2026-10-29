# Fatzomat – Arbeitsübergabe

Dieses Dokument ist der kompakte Übergabepunkt zwischen Chat-Sitzungen. Es beschreibt Arbeitsregeln und den zuletzt verifizierten Repository-Stand, nicht automatisch den Live-Zustand.

## Aktueller Live-Stand (2026-10-25, nach PR #319)

- `main` steht auf Commit `9bfdec19af800005feac781bb26f5333aee873da` (PR [#319](https://github.com/Connes/Fatzomat/pull/319), „Fix SVG icon color compatibility“).
- Ursache der roten CI: `flutter_svg 1.1.6` unterstützt bei `SvgPicture.asset` kein benanntes Argument `colorFilter`. Die beiden Aufrufe verwenden nun das kompatible Argument `color`.
- Regressionstest `test/regression/saved_recipes_menu_test.dart` wurde an die tatsächlichen SVG- und Material-Icons der Filterkategorien angepasst.
- Beide Workflows sind für den Merge-Commit erfolgreich: [Quality Gate](https://github.com/Connes/Fatzomat/actions/runs/40176076334) und [Flutter quality gate](https://github.com/Connes/Fatzomat/actions/runs/40176076291).
- Die PR wurde gemergt. Geräteprüfung wurde nicht durchgeführt. Vor der nächsten Aufgabe offene PRs und CI erneut live prüfen.

## Aktueller Live-Stand (2026-10-25, nach PR #323)

- `main` steht auf Commit `b4f72356d307d1ba5c37577ad5ff98981ec07967` (PR [#323](https://github.com/Connes/Fatzomat/pull/323), „Add strict selected-food option to ChatGPT recipe prompt“).
- Auf der Seite „Wir kochen“ gibt es unterhalb der Auswahl eine Checkbox „Nur diese Lebensmittel verwenden“.
- Aktiviert: Der ChatGPT-Prompt erlaubt als Lebensmittel nur Hauptauswahl und explizit ausgewählte Zutaten; Gewürze, Kräuter sowie Wasser/Salz/Pfeffer sind ausgenommen. Gilt für Vorschläge und das spätere Rezept.
- Deaktiviert: Der Prompt erlaubt passende zusätzliche Lebensmittel. Prompt-Regressionstests decken beide Modi ab.
- Beide Workflows auf dem Merge-Commit erfolgreich: [Flutter quality gate](https://github.com/Connes/Fatzomat/actions/runs/40179372235) und [Quality Gate](https://github.com/Connes/Fatzomat/actions/runs/40179372190).
- Keine Geräteprüfung durchgeführt. Vor der nächsten Aufgabe offene PRs und CI erneut live prüfen.

## Startregel für neue Chats

Wenn der Nutzer „Fatzomat weiterentwickeln“ schreibt:

1. Diese Datei lesen, dann den tatsächlichen Stand von `main`, offene PRs und aktuelle CI prüfen.
2. Bei Änderungen an Backend-Verhalten oder Migrationen den tatsächlichen Supabase-Stand separat prüfen.
3. Die nächste fachlich sinnvolle Aufgabe autonom umsetzen, passende Regressionstests ergänzen und relevante Qualitätsprüfungen ausführen.
4. Fehlerhafte Prüfungen untersuchen und beheben. Erfolg nur behaupten, wenn er für den konkreten Commit bestätigt ist.
5. Änderungen über nachvollziehbare Branches und PRs einreichen. Nach dem Merge `main` und CI erneut prüfen.
6. Diese Übergabe nach wesentlichen Änderungen aktualisieren. Alte Statusangaben nicht ungeprüft übernehmen.

GitHub, CI und Supabase sind maßgeblich. Dieses Dokument ist Arbeitsgedächtnis, kein Beweis für den Live-Zustand.

## Verbindlicher Kurz-Befehl: `Handover-Reset`

Wenn der Nutzer `Handover-Reset` schreibt, ohne weitere Erläuterung:

1. Diese HANDOVER.md und alle für die aktuelle Aufgabe relevanten Projektanweisungen erneut lesen.
2. Den tatsächlichen Live-Zustand der aktuellen Aufgabe prüfen: relevante Dateien und Änderungen, Branch/Commits, offene PRs, Merge-Status sowie erforderliche CI- und Testergebnisse. Frühere Gesprächs- oder Handover-Angaben nicht als aktuellen Nachweis behandeln.
3. Das bisherige Vorgehen gegen die Anweisungen prüfen, konkrete Abweichungen benennen und korrigieren.
4. Die aktuelle Aufgabe anschließend aktiv und innerhalb des bereits erteilten Auftrags fortsetzen. Fehler beheben, soweit autorisiert; nicht bei einer bloßen Analyse oder Entschuldigung stehen bleiben.
5. Keine eigenmächtigen Zusatzaufgaben oder unnötigen Änderungen beginnen. Bei fehlender Berechtigung, fehlendem Zugriff oder einer tatsächlich nötigen Nutzerentscheidung gezielt anhalten und nur den konkreten Blocker nennen.
6. Nur tatsächlich verifizierte Ergebnisse als erledigt oder erfolgreich melden. Erforderliche Prüfungen abwarten und nach Änderungen erneut für den aktuellen Commit kontrollieren.
7. Die bestehende Kommunikationsregel dieser Datei einhalten und erst dann berichten, wenn der vorgesehene Abschluss erreicht ist oder ein echter Blocker dies verhindert.

Der Befehl ist ein verbindlicher Prüf- und Korrekturauftrag, keine Bitte um bloße Zusammenfassung. Er gilt in neuen Chats, sofern dieses Repository und diese Datei dort zugänglich sind.

## Lebensmittelbilder entfernt (Arbeitsstand 2026-10-20)

- Nutzerwunsch umgesetzt in Commit `a0a4730566cb7cc102cf541204fe2322a04c78b0`: Lebensmittel-Präferenznamen und Kategorien linksbündig ausrichten und ungenutzte Lebensmittel-Illustrationen vollständig aus dem Repository entfernen.
- Die Lebensmittelzeilen zeigen keine Bilder, Icons, Emojis oder Platzhalter. `lib/features/foods/food_item_image.dart` ist derzeit ein Kompatibilitäts-Shim, der `SizedBox.shrink()` rendert; Widgettests prüfen, dass kein Bild und kein Layoutabstand entsteht.
- Die individuellen Lebensmittel-Illustrationsdateien und das Asset-Bundle `assets/foods/` sind nicht mehr in `main`. Die separaten Auswahlgrafiken unter `assets/food_choices/{cooking,delivery,restaurant}/` bleiben bestehen, da sie andere Auswahloberflächen bedienen und nicht die entfernten Lebensmittelzeilen illustrieren.
- Aktueller `main`-Commit: `a0a4730566cb7cc102cf541204fe2322a04c78b0`. Beide Post-Merge-CI-Workflows sind erfolgreich: [Quality Gate](https://github.com/Connes/Fatzomat/actions/runs/39466743842) und [Flutter quality gate](https://github.com/Connes/Fatzomat/actions/runs/39466743620).
- Die Liste offener PRs war bei der Prüfung leer. Geräteprüfung wurde nicht durchgeführt.

## Autonomer Arbeitsmodus

- „Fatzomat weiterentwickeln“ startet einen fortlaufenden Arbeitszyklus, nicht nur eine Bestandsaufnahme oder einen Vorschlag.
- Nach einem abgeschlossenen Schritt den nächsten sinnvollen, risikoarmen Schritt selbst bestimmen und im selben Arbeitsauftrag fortsetzen, ohne für jedes „Mach weiter“ eine neue Freigabe anzufordern.
- Fehlerursachen untersuchen, Fixes und Regressionstests implementieren, relevante CI-Läufe abwarten, rote Checks beheben und nach erfolgreicher Prüfung den PR-Workflow bis zum Merge und zur Post-Merge-Verifikation fortführen.
- Nur anhalten und den Nutzer einbeziehen, wenn eine fachliche Entscheidung tatsächlich nicht ableitbar ist, Zugang/Berechtigungen fehlen oder ein destruktiver Live-/Produktionsschritt ein wesentliches Risiko birgt.
- Keine Erfolge, Tests, Geräteprüfungen oder Live-Zustände behaupten, die nicht konkret verifiziert wurden.
- Autonom bedeutet nicht unbegrenzte Hintergrundarbeit nach Ende einer Sitzung: Beim nächsten Aufruf den tatsächlichen Zustand prüfen und den Arbeitszyklus nahtlos fortsetzen.

## Verbindlicher Entwicklungsworkflow

- Repository: `Connes/Fatzomat`; Hauptbranch: `main`.
- App: Flutter; CI verwendet Flutter 3.47.2 stable.
- Kommunikation mit dem Nutzer auf Deutsch.
- Nach Möglichkeit Umsetzung, Tests, PR und Verifikation autonom erledigen.
- Relevante Checks: Repository-Hygiene, `flutter analyze`, `flutter test` und weitere projektspezifische Prüfungen nach Bedarf.
- Nach Merge tatsächlichen `main`-Commit und Post-Merge-CI prüfen. Nicht aus einem erfolgreichen PR-Lauf auf den Zustand des Merge-Commits schließen.
- Der Nutzer führt lokal `git pull` aus und prüft die App auf seinem Gerät. Keine Geräteprüfung behaupten, solange sie nicht stattgefunden hat.

## PR-Reihenfolge und Merge-Gates

- Vor jeder Änderung den aktuellen `main`-Commit, alle offenen PRs, ihre Basis-/Head-Commits, Merge-Konflikte und die neuesten CI-Läufe direkt bei GitHub prüfen. Statusangaben aus älteren Chats oder dieser Datei sind kein Live-Nachweis.
- Ältere PRs zuerst prüfen und nach Möglichkeit zuerst abschließen. Die Nummer bzw. das Alter allein entscheidet nicht: Abhängigkeiten, überlappende Dateien und die Basis-Commits sind ausschlaggebend.
- PRs, die auf Änderungen eines anderen offenen PRs aufbauen, erst nach dessen Merge integrieren oder die Abhängigkeit ausdrücklich sauber abbilden. Keine abhängigen PRs so behandeln, als wären sie unabhängig.
- Vor jedem Merge müssen alle für den aktuellen Head-Commit erforderlichen CI-Checks erfolgreich sein und der PR mergebar sein. Bei roten Checks Logs lesen, Ursache beheben und die neuen Läufe abwarten. Nicht wegen Zeitdruck überspringen.
- Nach jedem Merge den tatsächlichen neuen `main`-Commit und dessen CI prüfen. Anschließend offene PRs erneut auf Aktualität, Konflikte, Basis und CI kontrollieren; Änderungen an `main` können frühere Prüfungen entwerten.
- Keine grünen Ergebnisse von einem älteren Commit auf einen neueren Commit oder den Merge-Commit übertragen. Nur den exakt geprüften Commit als erfolgreich bezeichnen.
- App-PRs erst als abgeschlossen melden, wenn sie gemergt und der resultierende `main`-Stand geprüft wurde. Lokale Geräteprüfung bleibt Aufgabe des Nutzers und darf nicht behauptet werden, solange sie nicht stattgefunden hat.
- **Abschluss-Checkliste ist Pflicht, nicht optional:** Vor einer Abschlussmeldung alle offenen PRs live abfragen und einzeln als offen, gemergt oder geschlossen ohne Merge klassifizieren. CI-Status und Merge-Status nicht aus dem Gesprächsverlauf ableiten.
- Für jeden PR, der zu einer Nutzeranforderung gehört: aktuellen Head prüfen, erforderliche Checks für exakt diesen Head abwarten, Merge durchführen, Merge-Ergebnis verifizieren und kontrollieren, dass die Änderung im aktuellen `main` enthalten ist. Anschließend Post-Merge-CI abwarten und offene PRs erneut abfragen.
- Ein erfolgreicher PR-CI-Lauf bedeutet **nicht**, dass der PR gemergt ist. Ein erfolgreicher Merge bedeutet **nicht**, dass die Änderung schon in der installierten Live-App sichtbar ist. Repository-Stand, CI-Stand und Live-/Gerätestand getrennt berichten.
- Wenn ein PR absichtlich nicht gemergt wird, muss der konkrete Grund genannt werden. Keine offene PR stillschweigend als erledigt behandeln. Vor der Abschlussmeldung muss die offene PR-Liste leer sein oder jeder verbleibende PR ausdrücklich mit Grund aufgeführt werden.
- Abschlussmeldung nur mit verifizierten Fakten: PR-Nummer/Link, Merge-Commit, Ergebnis der CI auf dem aktuellen `main` und gegebenenfalls klar benannter noch laufender Post-Merge-Prüfung. Nie „fertig“ sagen, wenn einer dieser erforderlichen Schritte noch offen ist.
- Bei mehreren offenen PRs eine klare Reihenfolge verfolgen: ältere unabhängige PRs mit grüner CI zuerst; danach abhängige PRs in Reihenfolge ihrer Voraussetzungen; nach jedem Merge neu validieren.
## Verbindlicher Abschlussmodus für Änderungsaufträge

Wenn der Nutzer eine konkrete Änderung beauftragt, gilt bis zum verifizierten Abschluss ein durchgehender Arbeitszyklus:

1. Den aktuellen Live-Stand und die relevanten Projektanweisungen prüfen, dann die angeforderte Änderung auf einem Branch implementieren und passende Regressionstests ergänzen.
2. Die relevanten lokalen/CI-Prüfungen ausführen. Bei jedem Fehler Logs und Ursache untersuchen, den Fix selbst implementieren und die betroffenen Prüfungen erneut ausführen. Ein roter CI-Lauf ist kein Grund, die Aufgabe an den Nutzer zurückzugeben.
3. Den Zyklus aus Fix und Prüfung wiederholen, bis alle erforderlichen Prüfungen für den aktuellen Commit erfolgreich sind. Ergebnisse älterer Commits gelten nicht für neuere Commits.
4. Den PR auf Merge-Bedingungen prüfen, nach erfolgreicher CI mergen und danach den tatsächlichen Merge-Commit in `main` sowie die Post-Merge-CI verifizieren.
5. Erst danach eine Abschlussmeldung senden. Sie nennt knapp PR-Link, Merge-Commit und verifizierte CI-Ergebnisse. Niemals eine Änderung als fertig melden, solange sie nur auf einem Branch liegt oder notwendige Prüfungen noch laufen/fehlschlagen.
6. Nur bei einem echten Blocker anhalten: fehlende Berechtigungen/Zugriffe, erforderliche fachliche Nutzerentscheidung oder ein risikoreicher/destruktiver Schritt, der Rücksprache verlangt. Dann ausschließlich den konkreten Blocker nennen und bereits sichere, autorisierte Arbeit fortsetzen, sobald er entfällt.

Keine Zwischenstands- oder Fortschrittsmeldungen während dieses Arbeitszyklus. Bei erneutem Nutzeraufruf zuerst den Live-Stand prüfen und denselben Auftrag nahtlos fortsetzen, statt bei null anzufangen.

## Kommunikationsregel: nur konkrete Schritte

- **Rückmeldung erst nach vollständigem Abschluss:** Während eines autonomen Arbeitszyklus keine Zwischenstands- oder Fortschrittsmeldungen senden. Erst berichten, wenn der PR gemergt ist, die Änderung im aktuellen `main` verifiziert wurde und die Post-Merge-CI geprüft ist.
- Vor dieser Abschlussmeldung offene PRs und deren Status live prüfen. Die Meldung knapp halten und PR-Link, Merge-Commit sowie den konkret verifizierten CI-Status nennen. Wenn ein externer Blocker oder eine notwendige Nutzerentscheidung den Abschluss verhindert, nur dann melden und den konkreten Blocker nennen.
- Einen fehlenden oder nicht abrufbaren CI-Status nicht als Erfolg werten. Den Arbeitszyklus weiterführen und Prüfungen erneut abfragen, soweit dies mit den verfügbaren Werkzeugen möglich ist.
- Bei Fehlerbehebungen und gemeinsamer Entwicklungsarbeit kurz und handlungsorientiert antworten.
- Wenn der Nutzer lokal etwas ausführen muss, **nur die konkret auszuführenden Befehle bzw. Schritte nennen**, in der richtigen Reihenfolge.
- Keine langen Erklärungen, keine unnötigen Hintergrundinformationen und insbesondere keine Listen mit Dingen, die der Nutzer nicht tun soll.
- Wenn ein Schritt eine Prüfung erfordert, den passenden Prüf-Befehl direkt angeben.
- Nur dann zusätzliche Erklärung geben, wenn sie nötig ist, um Datenverlust, Sicherheitsrisiken oder einen irreversiblen Fehler zu verhindern.
- Aufgaben, die autonom über Repository-/GitHub-Werkzeuge erledigt werden können, selbst ausführen, statt den Nutzer unnötig mit manuellen Schritten zu belasten.
- Nach Abschluss knapp das Ergebnis und den nächsten erforderlichen Befehl nennen. Keine überflüssigen Abschlussfragen.

## Projektgrenzen und Sicherheit

- Fatzomat ist für den privaten Gebrauch des Nutzers bestimmt. Öffentliches GitHub-Repository bedeutet keine öffentliche App-Verteilung.
- Keine Release-Builds und keine Veröffentlichung/Verteilung im normalen Workflow. Lokale Debug-Builds und Tests sind erlaubt.
- Keine unnötige Release-/Store-Konfiguration hinzufügen.
- Secrets, Tokens und Service-Role-Keys niemals ausgeben oder protokollieren.
- Live-Supabase-Änderungen und Deployments separat verifizieren; ein GitHub-Merge aktualisiert nicht automatisch ein Live-System.
- Vor destruktiven Live-Datenbankänderungen oder risikoreichen Aktionen sorgfältig prüfen und bei wesentlichem Risiko vorher Rücksprache halten.
- Migrationen versioniert und nachvollziehbar halten.

## Aktueller Repository-Stand (geprüft 2026-10-19)

- `main` enthält PR [#234 – Prevent duplicate restaurant completion actions](https://github.com/Connes/Fatzomat/pull/234), Merge-Commit `e71c725c898b0ac7b44c0e9067df5564a4d09533`.
- Die Restaurant-Detailaktion `Erledigt` wird während des asynchronen Abschlusses deaktiviert, damit schnelle Mehrfach-Taps keine parallelen Abschlussversuche auslösen. Bei fehlgeschlagenem Abschluss wird die Aktion wieder aktiviert.
- Regressionstest für den In-Flight-Zustand ergänzt.
- Für den PR-Head `d6cdcbc28e79d1818b00b82cd3005543b2923224` waren beide Qualitätsworkflows erfolgreich: `Quality Gate` (Run 846; Test und Analyze) sowie `Flutter quality gate` (Run 1486; Hygiene, Analyze und Test).
- Auf dem Merge-Commit `e71c725c898b0ac7b44c0e9067df5564a4d09533` wurden bei der Prüfung keine Post-Merge-Workflow-Runs und keine Statuschecks zurückgegeben; Post-Merge-CI ist daher **nicht als erfolgreich verifiziert**.
- Supabase-Live-Status und Geräteverhalten wurden nicht geprüft.

## Live-Status (verifiziert 2026-10-23)

- Aktueller `main`-Commit: `434120e65be9cf8cf3420a542594f2e7557e589d` (PR [#301 – Fix custom food saving and duplicate prevention](https://github.com/Connes/Fatzomat/pull/301)).
- Beide Post-Merge-CI-Workflows sind für exakt diesen Commit erfolgreich: [Quality Gate](https://github.com/Connes/Fatzomat/actions/runs/39958328215) und [Flutter quality gate](https://github.com/Connes/Fatzomat/actions/runs/39958328233).
- Die Live-Abfrage offener Pull Requests ergab keine offenen PRs.
- Die Migration zur Verhinderung normalisierter Duplikate benutzerdefinierter Lebensmittel wurde auf dem Live-Supabase-Projekt `oidxezjdwqktpxuypbfb` angewendet und read-only verifiziert. Die Datenbank registrierte sie unter Version `20261023132447`; der Repository-Dateiname verwendete zunächst `20261023150000`. Ein Folge-PR gleicht den Dateinamen an die tatsächlich registrierte Live-Version an.
- Vor der Migration wurde geprüft, dass keine benutzerdefinierten Lebensmittel mit gleichem kleingeschriebenem, getrimmtem Namen existieren. Der Unique-Index `foods_custom_name_normalized_unique` ist in der Live-Datenbank vorhanden. Keine vorhandenen Datensätze wurden verändert.
- Geräteprüfung wurde nicht durchgeführt.

## Nächster Schritt

1. Zu Beginn jeder Sitzung `main`, offene PRs und CI live erneut prüfen.
2. Nur den aktuellen Live-Status in diesem Abschnitt aktualisieren; historische Einzelberichte gehören in die jeweiligen thematischen Abschnitte.
3. Den nächsten Arbeitspunkt aus einem aktuellen Code-/Testbefund ableiten; geschlossene, nicht gemergte Feature-Branches nicht ungeprüft wiederverwenden.

## Technische Orientierung

- Für Tests und Regressionen die bestehenden Testmuster unter `test/` verwenden.
- Supabase-Migrationen liegen im Repository unter `supabase/migrations/`; Live-Anwendung und Funktionsdefinitionen müssen separat geprüft werden.
- Relevante dauerhafte Setup-, Sicherheits-, Test- und Release-Dokumentation liegt unter `docs/`. Diese Dokumente nicht durch historische Einzelberichte ersetzen.


## Technische Härtung: Restaurantaktionen und Supabase (2026-10-19)

Die Anwendungshärtung wurde über PR #235 in `main` integriert (Merge-Commit `5967bac43fcd650fc3d545ec59d77850fa5e31ff`). PR #236 gleicht die Dateinamen der beiden Security-Migrationen mit den angewendeten Live-Versionen ab. Dieser Folge-PR richtet zusätzlich die Cloud-Favoritenmigration an der Live-Migrationsversion aus.

- Restaurantdetails-Dialog: Favoriten-Toggle während eines laufenden Requests deaktivieren; Fehler zeigen eine generische Rückmeldung und geben die Aktion wieder frei. Fehler beim Restaurantabschluss werden ebenfalls abgefangen, ohne den Dialog fälschlich als erfolgreich zu schließen.
- Favoriten-Repository: Datenbank-Unique-Constraint-Fehler `23505` werden als bereits vorhandener Favorit behandelt. Beschädigte Legacy-JSON-Werte werden in einen separaten lokalen Backup-Key verschoben, bevor der aktive Migrationsschlüssel entfernt wird.
- Neue Widgettests prüfen doppelte Abschluss-Taps, Abschlussfehler, parallel gestartete Favoriten-Taps und Favoriten-Retry nach einem Fehler. Alle vier Tests liefen in der erfolgreichen PR-CI durch.
- Live-Supabase-Projekt `oidxezjdwqktpxuypbfb` wurde read-only geprüft: `restaurant_favorites` hat RLS aktiviert, eine `authenticated`-Policy mit `user_id = auth.uid()`, einen normalisierten Unique-Index auf Benutzer/Name/Adresse und derzeit keine doppelten normalisierten Identitäten. Das Tabellen-Schema ist im Live-Projekt vorhanden.
- Die Cloud-Favoritenmigration wurde auf `supabase/migrations/20261018045840_cloud_restaurant_favorites.sql` umbenannt, damit Dateiname und Live-Migrationshistorie dieselbe Version verwenden. Der Regressionstest wurde auf diesen Pfad aktualisiert; es wird keine zweite Tabellenmigration hinzugefügt.
- Der Supabase Security Advisor meldete `public.recipe_fingerprint(jsonb,jsonb)` mit veränderlichem `search_path`. Die Korrektur setzt ihn auf `pg_catalog, pg_temp`. Die Migration entzieht `anon` unnötige direkte Tabellenprivilegien und entfernt die permissive Policy `recipes global update`, die jedem `authenticated`-Benutzer Updates an beliebigen Rezepten erlaubte. Zusätzlich wurden `connection_member_display_name` und `is_connection_member` so gehärtet, dass sie nur noch Informationen für eine Verbindung zurückgeben, zu der der aufrufende Benutzer selbst gehört. Die globale Rezeptbibliothek bleibt lesbar, Änderungen bleiben auf Eigentümer beschränkt. Die Live-Tabelle `connection_members` enthält derzeit keine Zeilen; deshalb wurde die positive Mitgliedschaftsseite nicht mit realen Mitgliedsdaten getestet. Es wurden dafür keine Testdaten in Produktion angelegt.
- Die Migrationen wurden nach dem Merge auf das Live-Projekt angewendet und read-only verifiziert: Version `20261019181015` setzt den `search_path`, entfernt `recipes global update` und entzieht `anon` direkte Favoriten-Tabellenrechte; Version `20261019181043` entfernt auch unnötige `authenticated`-Privilegien und lässt nur `SELECT`, `INSERT`, `UPDATE`, `DELETE` übrig. Version `20261019181436` begrenzt die beiden Connection-Helper auf Mitglieder der jeweiligen Verbindung und pinnt auch dort den `search_path`. Die Owner-RLS-Policy bleibt aktiv. Die Funktionskonfiguration zeigt `search_path=pg_catalog, pg_temp`; die breite Rezept-UPDATE-Policy ist nicht mehr vorhanden; es gibt keine direkten `anon`-Tabellenrechte für Favoriten. Es wurden keine Produktionsdaten verändert.
- Das Live-Projekt hat 19 öffentliche Tabellen, und alle 19 haben RLS aktiviert. Verbleibende Advisor-Hinweise: 37 ausführbare `SECURITY DEFINER`-RPCs (einzeln auf Authentifizierungs- und Eigentümerprüfungen zu prüfen), `pg_net` in `public` und aktivierte anonyme Anmeldung. Anonyme Anmeldung wird von der App tatsächlich für Sitzungen verwendet und wurde deshalb nicht abgeschaltet. Diese Hinweise wurden nicht pauschal durch Änderungen an potenziell legitimen RPCs oder Auth-Einstellungen behandelt.
- Die PR-CI für PR #235 war erfolgreich: Quality Gate Run `39299597679` und Flutter quality gate Run `39300003522`. Auch beide Post-Merge-Push-Workflows auf Merge-Commit `5967bac43fcd650fc3d545ec59d77850fa5e31ff` waren erfolgreich: [Quality Gate Run 39300256920](https://github.com/Connes/Fatzomat/actions/runs/39300256920) und [Flutter quality gate Run 39300256908](https://github.com/Connes/Fatzomat/actions/runs/39300256908).


## UX-Härtung: Rezeptimport bei optionalem Bildfehler (2026-10-20)

- In Arbeit auf Branch `ux/recipe-import-save-feedback`: Wenn ein Rezept bereits erfolgreich gespeichert wurde, der optionale Bild-Upload danach aber fehlschlägt, soll der gesamte Import nicht fälschlich als fehlgeschlagen erscheinen. Das Rezept wird als gespeichert bestätigt, der Bildfehler separat angezeigt und die Vorschau wie im Erfolgsfall geschlossen.
- Regressionstest ergänzt. Lokale Flutter-Tests wurden über die GitHub-Datei-API nicht ausgeführt; PR-CI muss den aktuellen Stand verifizieren.
- Kein Accessibility-Refactoring. Kein Release oder Geräte-Test.


## UX-Härtung: Standortabfrage mit Timeout (2026-10-20)

- Standortbestimmung für die ChatGPT-Restaurantsuche ist jetzt auf 15 Sekunden begrenzt. Bei Timeout erscheint eine verständliche Fehlermeldung mit erneutem Versuch als nächstem Schritt; die UI bleibt nicht unbegrenzt im Ladezustand.
- Regressionstest ergänzt. CI muss den aktuellen PR-Head prüfen. Kein Geräte-Test und kein Release.


## UX-Härtung: Standortberechtigung erst bei Restaurantsuche (2026-10-20)

- Die Launch-Seite fordert keine Standortberechtigung mehr direkt beim ersten App-Start an. Die Berechtigung wird weiterhin im konkreten Restaurant-Suchablauf angefragt, in dem sie benötigt wird.
- Regressionstest aktualisiert. Keine Änderung an Berechtigungsmodellen oder Datenschutzkonfiguration. CI-Prüfung und Post-Merge-Verifikation stehen noch aus.


## UX-Härtung: Rezeptimport nach Teilerfolg fortsetzen (2026-10-21)

- Befund: `RecipeImportPreviewPage._save()` speichert das Rezept zuerst und verknüpft es danach optional mit „Heute“ oder löst eine gemeinsame Entscheidungsanfrage auf. Schlägt die spätere Verknüpfung fehl, blieb die Vorschau offen; ein erneuter Tap startete vorher erneut die Duplikatprüfung und konnte nicht sauber mit dem bereits gespeicherten Rezept fortfahren.
- Änderung auf Branch `fix/retry-recipe-import-finalization`: die erfolgreiche Rezept-ID bleibt im Vorschau-State erhalten. Erneute Versuche überspringen den Insert und setzen die nachgelagerte Verknüpfung fort. Das optionale Bild wird nicht bei jedem Retry erneut hochgeladen; ein Bildfehler bleibt in der Rückmeldung erhalten.
- Regressionstest prüft die Retry-Guard-Bedingung, den einmaligen Insert und die beiden Verknüpfungspfade. CI und Merge sind noch nicht abgeschlossen. Lokale Flutter-Tests und Gerätetests wurden nicht ausgeführt.


## Lebensmittel-Auswahl ohne Emojis (2026-10-21)

- In `lib/features/recipes/additional_ingredients_page.dart` wurden die Emoji-Zuordnung und das Emoji-Feld aus den auswählbaren Lebensmittelzeilen entfernt. Der Lebensmittelname beginnt jetzt links im Zeileninhalt; Checkbox und Auswahlverhalten bleiben unverändert.
- Regressionstest in `test/regression/additional_ingredients_test.dart` prüft, dass Emoji-Zeichen nicht gerendert werden und die Namensspalte links beginnt.
- Änderung eingereicht über Branch `fix/ingredient-picker-no-emojis`; CI/Merge-Status nach PR-Erstellung prüfen. Keine Geräteprüfung durchgeführt.


## Rezeptprompt: Internetfunde plus eigene Ideen (Arbeitsstand 2026-10-26)

- `lib/features/recipes/together_chatgpt_prompt.dart`: Phase 1 ist auf bis zu drei echte Internetrezepte plus genau zwei klar gekennzeichnete eigene Ideen ausgerichtet. Vorgesehene Websites in Reihenfolge: einfachkochen.de, chefkoch.de, emmikochteinfach.de (Emmi kocht einfach), lecker.de und essen-und-trinken.de.
- Prompt fordert Abbruch der Websuche nach spätestens 30 Sekunden, verbietet erfundene Quellen und jede inhaltliche Änderung an Originalrezepten und weist auf die Grenzen hin, wenn ein geschützter Originaltext nicht vollständig wiedergegeben werden darf.
- Bei weniger als drei passenden Internetfunden werden keine Treffer erfunden; es erscheinen nur tatsächlich verifizierte Funde plus zwei eigene Ideen. Dadurch kann die Vorschlagsliste 2 bis 5 Einträge enthalten.
- Das bestehende `together_recipe`-JSON-Schema Version 1 bleibt unverändert. Bei ausgewähltem Internetrezept darf eine JSON-Datei nicht fälschlich als unverändertes Original ausgegeben werden, wenn Quelle/Angaben nicht verlässlich übernommen werden können.
- Wichtig: Ein Prompt kann die 30-Sekunden-Grenze nur anweisen, nicht technisch garantieren. Eine harte Grenze erfordert Kontrolle durch die tatsächlich verwendete Suchumgebung. Die App übergibt den Prompt weiterhin an eine externe ChatGPT-Sitzung; die Suchfunktion hängt von dieser Sitzung ab.
- Geräteprüfung nicht durchgeführt. PR und CI-Status nach Einreichung prüfen.

## Restaurant-Suchprompt: Küchenbezeichnung strikt begrenzen (2026-10-26)

- `lib/features/food_modes/chatgpt_restaurant_page.dart`: Der Prompt verlangt jetzt für `restaurant.cuisine` exakt die vom Nutzer angefragte Küchenbezeichnung. Zusätze und Werbetexte wie „gutbürgerlich“, „regional und saisonal“, „authentisch“ oder „mediterran“ sind ausdrücklich verboten.
- Beispiele im Prompt: deutsche Küche muss als `Deutsch`, griechische Küche als `Griechisch` ausgegeben werden.
- `test/regression/chatgpt_restaurant_import_test.dart` prüft die verbindliche Regel und Beispiele.
- Über PR [#329](https://github.com/Connes/Fatzomat/pull/329) gemergt; Merge-Commit `d5e91a5335106f915accd3da78388d220c20bbbe`. Beide PR-CI-Workflows für den Head `8a3c4466b43a55e51c32ca6b114b8f792de2cdbf` erfolgreich: [Flutter quality gate](https://github.com/Connes/Fatzomat/actions/runs/40301683627) und [Quality Gate](https://github.com/Connes/Fatzomat/actions/runs/40301683661). Post-Merge-CI konnte über die verfügbare Abfrage noch nicht bestätigt werden; keine Geräteprüfung durchgeführt.

## Lieblingsrestaurants: Menü-Icons in Gold (2026-10-26)

- In `lib/features/settings/restaurant_favorites_page.dart` nutzen die drei Punkte auf jeder Restaurantkarte und ausschließlich das Bearbeiten-Icon im Popup-Menü `AppDesign.iconGold`.
- Die Texte bleiben unverändert; insbesondere wird „Bearbeiten“ nicht gold eingefärbt. Das Löschen-Icon und der Löschtext behalten die Fehlerfarbe.
- Regressionstest: `test/regression/restaurant_favorites_gold_menu_test.dart`.
- Über PR [#330](https://github.com/Connes/Fatzomat/pull/330) gemergt; Merge-Commit `3c6faf37e6f128881d8d88ce45e366fc33acb5ce`. Beide PR-CI-Workflows für den Head `b8bd0aebd4f54ccfb80aada565d15a08ebff3f91` erfolgreich: [Flutter quality gate](https://github.com/Connes/Fatzomat/actions/runs/40303638086) und [Quality Gate](https://github.com/Connes/Fatzomat/actions/runs/40303638154). Post-Merge-CI über die verfügbare Abfrage noch nicht bestätigt; keine Geräteprüfung durchgeführt.

## Einkaufsliste: alle geplanten Tage und fehlende Zutaten sichtbar machen (2026-10-26)

- `PersonalTodayRepository.plannedShoppingDates()` liefert heute plus alle zukünftigen Datumswerte mit persönlichen Rezeptplänen im Status `planned`; die Einkaufsliste hängt nicht länger an einem Dreitagesfenster.
- `MultiDayShoppingListPage` lädt Pläne für diese Datumswerte dynamisch. Beim Tageswechsel wird die Liste aktualisiert, ohne geplante Zukunftstage aus einer festen Dreitagesliste zu entfernen.
- Fehlerquelle in der bisherigen Darstellung: `_activeDays` blendete einen Tag komplett aus, wenn zu einem gespeicherten Rezeptplan keine Einkaufszeilen vorhanden waren. Dadurch sah es so aus, als wäre das Rezept nicht übernommen worden. Solche geplanten Rezepttage bleiben jetzt sichtbar, sodass der fehlende Zutatenbestand nicht mehr stillschweigend den ganzen Tag versteckt.
- Regressionstests ergänzt für unbegrenzte geplante Datumswerte und sichtbare Rezepttage ohne Einkaufszeilen.
- Diese Änderung stellt die Anzeige aller geplanten Tage sicher. Sie beweist noch nicht, dass fehlende Zutatenzeilen in der Datenbank automatisch repariert werden; die konkrete Synchronisation beim Speichern/Import des Rezepts muss anhand von Live-Daten und Datenbanktriggern weiter geprüft werden.
- Über PR [#331](https://github.com/Connes/Fatzomat/pull/331) gemergt; Merge-Commit `ab80c19be1edaf21fbc41eeac578cae53ebec334`. Beide CI-Workflows erfolgreich: [Flutter quality gate](https://github.com/Connes/Fatzomat/actions/runs/40313211551) und [Quality Gate](https://github.com/Connes/Fatzomat/actions/runs/40313211889). Keine Geräteprüfung durchgeführt.


## Einkaufsliste: nach App-Rückkehr neu laden (2026-10-26)

- `MultiDayShoppingListPage.didChangeAppLifecycleState()` lädt die gespeicherten Pläne und Einkaufsartikel beim Wechsel zurück in den Vordergrund erneut, auch wenn sich das Datum nicht geändert hat. Die Seite kann in der Tab-Navigation gemountet bleiben; ein App-Resume darf daher nicht allein auf den Tageswechsel oder Realtime-Ereignisse vertrauen.
- Ziel ist, einen veralteten UI-Zustand nach Hintergrundbetrieb zu vermeiden. Das ist eine defensive Verbesserung, keine bestätigte Erklärung des zuvor beobachteten Fehlers; der Fehler war nicht reproduzierbar.
- Über PR [#332](https://github.com/Connes/Fatzomat/pull/332) gemergt; Merge-Commit `1ad48e585e27f081ce1ed013350783667102cb7d`. Beide PR-CI-Workflows auf dem Head waren erfolgreich: `Quality Gate` und `Flutter quality gate`. Post-Merge-CI und Geräteprüfung separat verifizieren.


## Einkaufsliste: leerer Zustand vs. fehlgeschlagener Abruf (2026-10-26)

- `PersonalTodayRepository.plannedShoppingDates()` und `plannedPlansForDate()` werfen jetzt `AuthenticationException`, wenn keine angemeldete Sitzung vorhanden ist, statt eine leere Datums-/Planliste zurückzugeben. Eine abgelaufene Sitzung kann dadurch nicht mehr wie eine wirklich leere Einkaufsliste aussehen.
- `MultiDayShoppingListPage` zeigt bei fehlender Sitzung eine passende Anmeldeaufforderung. Andere Abruffehler zeigen die normalisierte Fehlerursache und behalten die Schaltfläche „Erneut versuchen“. Die Meldung „Noch keine Einkaufsliste“ bleibt dem erfolgreich geladenen leeren Zustand vorbehalten.
- Regressionstest ergänzt, der die Trennung zwischen fehlender Sitzung, Abruffehler und echtem Leerzustand absichert.
- Änderung auf Branch `fix/shopping-list-empty-vs-error`; PR/CI noch ausstehend. Geräteprüfung nicht durchgeführt.

## Rezeptkarten im Kochablauf (Arbeitsstand 2026-10-26)

- Branch `fix/cook-filtered-recipe-card-layout`: Die gefilterte Rezeptliste unter „Wir kochen“ → „Aus meinen Rezepten suchen“ verwendet jetzt die Kartenanordnung der regulären Rezeptbibliothek: Bild und Name nebeneinander, Auswahlaktion darunter, gleiche Innenabstände und zweizeilige Namensbegrenzung.
- Der kontextabhängige Funktionsumfang bleibt getrennt: Bearbeiten, Teilen und Löschen bleiben ausschließlich in „Meine Rezepte“ verfügbar. Die Kochsuche bietet weiterhin nur „Für heute auswählen“ bzw. „Für diesen Tag auswählen“.
- Regressionstest ergänzt in `test/regression/saved_recipes_today_selection_test.dart`, um Layout und Trennung der Aktionen abzusichern.
- PR/CI und Gerätetest sind für diesen Arbeitsstand noch nicht verifiziert.

## Einkaufsliste: Einzelrezept-Kopfzeile (Arbeitsstand 2026-10-26)

- Branch `feat/single-recipe-shopping-list-heading`: Wenn genau ein Rezept für genau einen ausgewählten Tag in der persönlichen Einkaufsliste angezeigt wird, ersetzt das zentrierte Datum und der darunter zentrierte Rezeptname die Überschrift „Zusammengefasste Zutaten“.
- Bei einer einzelnen Rezept-Einkaufsliste heißt die Zutatenkategorie „Zutaten“ statt „Weitere Zutaten“. Bei mehreren Rezepten bleibt die bisherige zusammengefasste Darstellung mit Kategorien erhalten.
- Regressionstest in `test/regression/shopping_list_test.dart` ergänzt. PR/CI und Gerätetest noch ausstehend.


### Anforderungsänderung: einheitliche Tageskarte (2026-10-26)

Die vorherige Sonderdarstellung für genau ein Rezept wurde verworfen. Die Einkaufsliste soll für einen oder mehrere Tage denselben Aufbau verwenden: immer eine ausklappbare Tageskarte mit Datum und Auswahl-Checkbox; beim Aufklappen stehen Rezeptname und Personenzahl. Nur ausgewählte Tage speisen die Zutatenliste. Ist kein Tag ausgewählt, wird statt der Zutaten der Hinweis „Keine Einkaufsliste ausgewählt …“ angezeigt. Die Überschrift „Zusammengefasste Zutaten“ und die bisherigen Kategorien bleiben einheitlich.


## Rezeptdetail aus „Wir kochen“ schreibgeschützt (2026-10-28)

- Wenn ein gespeichertes Rezept aus dem Kochablauf über „Aus meinen Rezepten suchen“ geöffnet wird, zeigt die Rezeptdetailseite weiterhin die zentrierte Überschrift „Rezept“, aber keine Verwaltungsaktionen für Export, Bild, Bearbeiten oder Löschen.
- Die Verwaltungsaktionen bleiben in der normalen Rezeptbibliothek „Meine Rezepte“ verfügbar. Die Unterscheidung erfolgt über `showManagementActions`, getrennt von `viewingTodaySelection`, damit bestehende Kochschritt-Funktionen nicht unbeabsichtigt verändert werden.
- Regressionstest in `test/regression/recipe_detail_compact_test.dart` ergänzt. PR/CI und Gerätetest stehen noch aus.


## Internetrezepte aus ChatGPT zuverlässig importieren (2026-10-28)

- Ursache des beobachteten Verhaltens: Der Prompt in `lib/features/recipes/together_chatgpt_prompt.dart` verlangte einerseits ein unverändertes Originalrezept, untersagte zugleich aber eine vollständige Übernahme und wies ChatGPT ausdrücklich an, in diesem Fall keine `together_recipe.json` zu erstellen. Das war widersprüchlich und führte zu der Ablehnung im Screenshot.
- Prompt angepasst: ChatGPT soll die Originalseite tatsächlich öffnen und Zutaten/Mengen prüfen, die Zubereitung in eigenen Worten formulieren, die Quelle mit vollständiger URL in der Beschreibung erhalten und danach eine gültige `together_recipe.json` erzeugen.
- Wenn die Seite technisch nicht erreichbar oder wichtige Angaben nicht sichtbar sind, soll ChatGPT offen nach dem Rezepttext oder Screenshots fragen, statt zu raten oder pauschal abzulehnen.
- Regressionstests in `test/together_chatgpt_prompt_test.dart` prüfen diese Regeln.
- Wichtig: Der Prompt kann keine Browser-/Webzugriffsrechte erzwingen. Die tatsächliche Extraktion hängt davon ab, ob die verwendete ChatGPT-Sitzung Websuche/Browsing nutzen kann und die Quellseite erreichbar ist. CI und Gerätetest stehen noch aus.


## Fallback für nicht erreichbare Rezept-Webseiten (2026-10-28)

- Folgeanalyse des Chefkoch-Screenshots: Die bisherige Prompt-Korrektur forderte zwar, die Originalseite erneut zu öffnen, gab aber keinen konkreten Wiederherstellungsweg vor, wenn Chefkoch den Zugriff blockiert. Dadurch blieb ChatGPT beim Fehler stehen und bat sofort um manuelle Screenshots.
- Prompt jetzt mit begrenztem Fallback: exakten Rezepttitel suchen, eine alternative zugängliche Quelle mit Zutaten/Mengen prüfen und die tatsächlich verwendete URL angeben. Die blockierte Originalseite darf nicht als gelesen dargestellt werden.
- Wenn Angaben nicht ausreichend verifizierbar sind, soll ChatGPT nur gezielt fehlende Angaben anfordern, statt Mengen zu erfinden oder Vollständigkeit vorzutäuschen.
- Regressionstests prüfen die Fallback-Anweisungen.
- Technische Grenze bleibt: Der App-Prompt selbst kann keinen Webzugriff bereitstellen und eine Webseite nicht aus der App heraus entsperren. Der Fallback verbessert das Verhalten nur, wenn ChatGPT-Websuche eine andere zugängliche Quelle findet. CI und echter ChatGPT-Gerätetest stehen noch aus.


## Launch-Artwork: seitliche Bildkante abgesichert (2026-10-29)

- Nach PR #346 liegt die Gemüseillustration auf dem Launchscreen in einem `ClipRect` und wird horizontal mit `scaleX: 1.04` vergrößert, damit eingebettete Randlinien nicht als sichtbare Naht am Bildschirmrand erscheinen.
- Regressionstest `test/regression/launch_artwork_test.dart` sichert den Clip, den horizontalen Zuschnitt und die unveränderte Bildausrichtung ab.
- Der Test ist ein Quelltext-Vertragstest und ersetzt keine visuelle Geräteprüfung.
- Über PR [#347](https://github.com/Connes/Fatzomat/pull/347) gemergt; Merge-Commit `1955241eb8c6a1b283cf5c53ed02a5785f8b7a67`. Der Regressionstest `test/regression/launch_artwork_test.dart` schützt den Zuschnitt. Die beiden PR-Workflows waren erfolgreich; visuelle Geräteprüfung nicht durchgeführt.


## Überrasch-mich: Gewinner im Mittelpunkt animieren (Arbeitsstand 2026-10-29)

- In `lib/features/shared/surprise_mode_roulette_page.dart` blendet sich der Fatzomat nach dem Stoppen per Fade-/Scale-Übergang aus, während die Gewinnerkategorie aus nahezu unsichtbarer Größe langsam ins Zentrum wächst.
- Nach dem Einblenden pulsiert die Gewinnerkarte dezent weiter. Die Buttons „NOCHMAL DREHEN“ und „WEITER MIT …“ bleiben darunter erhalten.
- „NOCHMAL DREHEN“ setzt Einblend- und Pulsanimation zurück und startet die Walzen neu; die nächste Gewinneranzeige beginnt damit wieder von vorn.
- Regressionstest: `test/regression/surprise_winner_focus_animation_test.dart`.
- Über PR [#348](https://github.com/Connes/Fatzomat/pull/348) gemergt; Merge-Commit `b63ca808b46a91918b706da1069725528538d449`. Beide PR-Workflows waren für den Head `9ea8dde4fbc19dc7d8822793321834b9af9d1b17` erfolgreich. Post-Merge-CI wird separat geprüft; visuelle Geräteprüfung nicht durchgeführt.
