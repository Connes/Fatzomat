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

- `main` war beim Prüfen auf Commit `871f518db5a3a44337aa3d7c2062baca820c39d9` (`Show only selected order on Today decision card`), gemergt am 2026-10-16.
- PR #169 ist gemergt: Bestellentscheidungen zeigen auf der Heute-Karte nur die gewählte Option, z. B. „Sushi“, und die vertikalen Abstände wurden angeglichen.
- PR #168 ist gemergt: Nach Restaurantimport wird `Navigator.pop(true)` nur aufgerufen, wenn der Navigator tatsächlich eine Route zurückgehen kann.
- PR #167 ist gemergt: gemeinsames Layout der Heute-Entscheidungskarte für Kochen, Bestellen und Restaurantbesuch.
- PR #170 wurde am 2026-10-17 gemergt. Der Merge-Commit war `b57f9de5c324d451cd6469f2b44aa0e0102a02f8`; beide Post-Merge-CI-Workflows waren erfolgreich.
- PR #171 entfernt historische Markdown-Changelogs und einmalige Berichte. Aktueller Status vor dem Merge prüfen.
- PR #172 ergänzt Restaurantkategorien und entfernt den unteren ChatGPT-Suchbutton. Beide CI-Workflows waren am Head `04879fc8b27f029096bc41277ddb987050790365` erfolgreich; vor Merge aktuellen Head, Basis und Mergebarkeit erneut prüfen.
- PR #173 gestaltet den Button „Entscheide Du“ auf der Heute-Seite neu. Beide CI-Workflows waren am Head `9a4780f3ec2073dd487a9b1149bbd93306bd93fe` erfolgreich; vor Merge aktuellen Head, Basis und Mergebarkeit erneut prüfen.
- Für den genannten aktuellen `main`-Commit lieferte die verfügbare GitHub-Schnittstelle bei dieser Aktualisierung keine Workflow-Runs und keine Statuschecks. Daher wird der CI-Status hier ausdrücklich **nicht als verifiziert grün** angegeben. Beim nächsten Arbeitsbeginn erneut prüfen.
- Supabase-Live-Status wurde im Rahmen dieser Handover-Aktualisierung nicht geprüft. Keine Annahmen über aktive Migrationen oder Deployment-Versionen treffen.

## Nächster Schritt

1. Beim nächsten Arbeitsbeginn den aktuellen `main`-Commit, offene PRs und CI direkt bei GitHub erneut prüfen.
2. Frühere Handover-Notizen enthielten eine Diagnose zum Rezeptbild-Upload und zur Erstellung signierter Storage-URLs. Den aktuellen Code und, falls diese Funktion weiterhin relevant ist, das tatsächliche Verhalten separat prüfen, bevor daraus eine offene Aufgabe oder ein erledigter Fix abgeleitet wird.
3. Danach die nächste vom Nutzer gewünschte Änderung priorisieren. Keine bereits gemergten Roulette- oder Auswahlkarten-Fixes erneut bearbeiten, sofern kein neuer Fehler beobachtet wird.

## Technische Orientierung

- Für Tests und Regressionen die bestehenden Testmuster unter `test/` verwenden.
- Supabase-Migrationen liegen im Repository unter `supabase/migrations/`; Live-Anwendung und Funktionsdefinitionen müssen separat geprüft werden.
- Relevante dauerhafte Setup-, Sicherheits-, Test- und Release-Dokumentation liegt unter `docs/`. Diese Dokumente nicht durch historische Einzelberichte ersetzen.
