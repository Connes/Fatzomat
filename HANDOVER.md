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
## Kommunikationsregel: nur konkrete Schritte

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

## Zuletzt verifizierter Repository-Stand

- `main` steht beim Prüfen auf Merge-Commit `6948ac1de7d2a8836d480c048440f347361d2681` (`style: polish Today decide-you action (#177)`), gemergt am 2026-10-17.
- PR #170 aktualisierte diese Übergabe; PR #171 entfernte historische Markdown-Changelogs und einmalige Berichte.
- PR #175 ergänzte verbindliche Merge-Gates und Statuspflege.
- PR #176 ist gemergt: Restaurantkategorien wurden ergänzt; der separate untere ChatGPT-Suchbutton wurde entfernt, die direkte Suche über die Kategorie bleibt Bestandteil des Flows.
- PR #177 ist gemergt: Der CTA „Entscheide Du“ auf der Heute-Seite wurde visuell überarbeitet; Regressionserwartungen wurden an die tappbare Fläche angepasst.
- Die vorherigen PRs #172 und #173 wurden nicht gemergt; ihre überarbeiteten Nachfolger #176 und #177 wurden auf aktualisierter Basis gemergt.
- Die GitHub-Schnittstelle liefert für `6948ac1de7d2a8836d480c048440f347361d2681` aktuell weder Combined-Statuschecks noch Workflow-Runs. CI ist deshalb **nicht verifiziert grün**. Vor weiteren Merges erneut direkt prüfen.
- Die GitHub-Suche lieferte keine offenen Issues oder Pull Requests; wegen der bekannten Einschränkungen der Suchschnittstelle sollte dies vor der nächsten Änderung erneut geprüft werden.
- Supabase-Live-Status wurde nicht geprüft. Keine Annahmen über aktive Migrationen oder Deployment-Versionen treffen.

## Nächster Schritt

1. Bei der nächsten Sitzung `main`, offene PRs und CI erneut live prüfen.
2. Vor einer neuen Funktion einen aktuellen Code-/Testbefund als nächsten Arbeitspunkt festlegen; alte Feature-Branches sind stark hinter `main` und dürfen nicht ungeprüft wiederverwendet werden.
3. Rezeptbild-Upload und signierte Storage-URLs nur dann weiter untersuchen, wenn die Funktion im aktuellen Code noch relevant ist oder ein reproduzierbarer Fehler vorliegt.

## Technische Orientierung

- Für Tests und Regressionen die bestehenden Testmuster unter `test/` verwenden.
- Supabase-Migrationen liegen im Repository unter `supabase/migrations/`; Live-Anwendung und Funktionsdefinitionen müssen separat geprüft werden.
- Relevante dauerhafte Setup-, Sicherheits-, Test- und Release-Dokumentation liegt unter `docs/`. Diese Dokumente nicht durch historische Einzelberichte ersetzen.


## Änderung in Arbeit (2026-10-18)

- Feature-Branch `refactor/shared-decision-card-actions`: Aktionsbereich der Heute-Entscheidungskarte in `_TodayDecisionCardActions` extrahiert. Horizontale Trennlinie und Aktionen „Teilen“/„Entfernen“ sind damit zentral wiederverwendbar; der Erledigt-Zustand bleibt erhalten.
- Regressionstests werden auf die extrahierte Komponente angepasst. CI und Merge-Status nach PR-Erstellung live prüfen.
