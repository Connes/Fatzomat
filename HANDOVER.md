# Fatzomat – Arbeitsübergabe

Dieses Dokument ist der kompakte Übergabepunkt zwischen Chat-Sitzungen. Es beschreibt Arbeitsregeln und den zuletzt verifizierten Repository-Stand, nicht automatisch den Live-Zustand.

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

## Nächster Schritt

1. Zu Beginn jeder Sitzung `main`, offene PRs und CI live erneut prüfen.
2. Nur die letzte aktuelle Änderung in diesem Dokument zusammenfassen. Historische PR-Listen und alte Sitzungsberichte gehören nicht hierher.
3. Den nächsten Arbeitspunkt aus einem aktuellen Code-/Testbefund ableiten; alte Feature-Branches nicht ungeprüft wiederverwenden.

## Technische Orientierung

- Für Tests und Regressionen die bestehenden Testmuster unter `test/` verwenden.
- Supabase-Migrationen liegen im Repository unter `supabase/migrations/`; Live-Anwendung und Funktionsdefinitionen müssen separat geprüft werden.
- Relevante dauerhafte Setup-, Sicherheits-, Test- und Release-Dokumentation liegt unter `docs/`. Diese Dokumente nicht durch historische Einzelberichte ersetzen.


## Technische Härtung: Restaurantaktionen und Supabase (2026-10-19)

Die Anwendungshärtung wurde über PR #235 in `main` integriert (Merge-Commit `5967bac43fcd650fc3d545ec59d77850fa5e31ff`). Dieser Folge-Branch gleicht die SQL-Migrationsdateinamen mit der tatsächlich angewendeten Supabase-Migrationshistorie ab.

- Restaurantdetails-Dialog: Favoriten-Toggle während eines laufenden Requests deaktivieren; Fehler zeigen eine generische Rückmeldung und geben die Aktion wieder frei. Fehler beim Restaurantabschluss werden ebenfalls abgefangen, ohne den Dialog fälschlich als erfolgreich zu schließen.
- Favoriten-Repository: Datenbank-Unique-Constraint-Fehler `23505` werden als bereits vorhandener Favorit behandelt. Beschädigte Legacy-JSON-Werte werden in einen separaten lokalen Backup-Key verschoben, bevor der aktive Migrationsschlüssel entfernt wird.
- Neue Widgettests prüfen doppelte Abschluss-Taps, Abschlussfehler, parallel gestartete Favoriten-Taps und Favoriten-Retry nach einem Fehler. Alle vier Tests liefen in der erfolgreichen PR-CI durch.
- Live-Supabase-Projekt `oidxezjdwqktpxuypbfb` wurde read-only geprüft: `restaurant_favorites` hat RLS aktiviert, eine `authenticated`-Policy mit `user_id = auth.uid()`, einen normalisierten Unique-Index auf Benutzer/Name/Adresse und derzeit keine doppelten normalisierten Identitäten. Das Tabellen-Schema ist im Live-Projekt vorhanden.
- Die SQL-Quelle für Cloud-Favoriten existiert bereits unter `supabase/migrations/20261017120000_cloud_restaurant_favorites.sql`. Die Live-Migrationshistorie führt denselben Namen allerdings unter Version `20261018045840`; dieser Versionsunterschied ist dokumentiert und es wurde keine doppelte Tabellenmigration hinzugefügt.
- Der Supabase Security Advisor meldete `public.recipe_fingerprint(jsonb,jsonb)` mit veränderlichem `search_path`. Die Korrektur setzt ihn auf `pg_catalog, pg_temp`. Die Migration entzieht `anon` unnötige direkte Tabellenprivilegien und entfernt die permissive Policy `recipes global update`, die jedem `authenticated`-Benutzer Updates an beliebigen Rezepten erlaubte. Zusätzlich wurden `connection_member_display_name` und `is_connection_member` so gehärtet, dass sie nur noch Informationen für eine Verbindung zurückgeben, zu der der aufrufende Benutzer selbst gehört. Die globale Rezeptbibliothek bleibt lesbar, Änderungen bleiben auf Eigentümer beschränkt.
- Die Migrationen wurden nach dem Merge auf das Live-Projekt angewendet und read-only verifiziert: Version `20261019181015` setzt den `search_path`, entfernt `recipes global update` und entzieht `anon` direkte Favoriten-Tabellenrechte; Version `20261019181043` entfernt auch unnötige `authenticated`-Privilegien und lässt nur `SELECT`, `INSERT`, `UPDATE`, `DELETE` übrig. Version `20261019181436` begrenzt die beiden Connection-Helper auf Mitglieder der jeweiligen Verbindung und pinnt auch dort den `search_path`. Die Owner-RLS-Policy bleibt aktiv. Die Funktionskonfiguration zeigt `search_path=pg_catalog, pg_temp`; die breite Rezept-UPDATE-Policy ist nicht mehr vorhanden; es gibt keine direkten `anon`-Tabellenrechte für Favoriten. Es wurden keine Produktionsdaten verändert.
- Das Live-Projekt hat 19 öffentliche Tabellen, und alle 19 haben RLS aktiviert. Verbleibende Advisor-Hinweise: 37 ausführbare `SECURITY DEFINER`-RPCs (einzeln auf Authentifizierungs- und Eigentümerprüfungen zu prüfen), `pg_net` in `public` und aktivierte anonyme Anmeldung. Anonyme Anmeldung wird von der App tatsächlich für Sitzungen verwendet und wurde deshalb nicht abgeschaltet. Diese Hinweise wurden nicht pauschal durch Änderungen an potenziell legitimen RPCs oder Auth-Einstellungen behandelt.
- Die PR-CI für PR #235 war erfolgreich: Quality Gate Run `39299597679` und Flutter quality gate Run `39300003522`. Auch beide Post-Merge-Push-Workflows auf Merge-Commit `5967bac43fcd650fc3d545ec59d77850fa5e31ff` waren erfolgreich: [Quality Gate Run 39300256920](https://github.com/Connes/Fatzomat/actions/runs/39300256920) und [Flutter quality gate Run 39300256908](https://github.com/Connes/Fatzomat/actions/runs/39300256908).
