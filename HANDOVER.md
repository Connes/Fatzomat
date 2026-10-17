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

## Projektgrenzen und Sicherheit

- Fatzomat ist für den privaten Gebrauch des Nutzers bestimmt. Öffentliches GitHub-Repository bedeutet keine öffentliche App-Verteilung.
- Keine Release-Builds und keine Veröffentlichung/Verteilung im normalen Workflow. Lokale Debug-Builds und Tests sind erlaubt.
- Keine unnötige Release-/Store-Konfiguration hinzufügen.
- Secrets, Tokens und Service-Role-Keys niemals ausgeben oder protokollieren.
- Live-Supabase-Änderungen und Deployments separat verifizieren; ein GitHub-Merge aktualisiert nicht automatisch ein Live-System.
- Vor destruktiven Live-Datenbankänderungen oder risikoreichen Aktionen sorgfältig prüfen und bei wesentlichem Risiko vorher Rücksprache halten.
- Migrationen versioniert und nachvollziehbar halten.

## Zuletzt verifizierter Repository-Stand

- `main` war beim Prüfen auf Commit `871f518db3a5a44337aa3d7c2062baca820c39d9` (`Show only selected order on Today decision card`), gemergt am 2026-10-16.
- PR #169 ist gemergt: Bestellentscheidungen zeigen auf der Heute-Karte nur die gewählte Option, z. B. „Sushi“, und die vertikalen Abstände wurden angeglichen.
- PR #168 ist gemergt: Nach Restaurantimport wird `Navigator.pop(true)` nur aufgerufen, wenn der Navigator tatsächlich eine Route zurückgehen kann.
- PR #167 ist gemergt: gemeinsames Layout der Heute-Entscheidungskarte für Kochen, Bestellen und Restaurantbesuch.
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
