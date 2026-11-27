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
- Relevante Pflicht-Checks bei jedem PR: Repository-Hygiene, `flutter analyze`, `flutter test` und ein erfolgreicher iOS-Build. Weitere projektspezifische Prüfungen nach Bedarf. Der iPhone-Simulator-Smoke-Test ist kein allgemeines Merge-Gate; siehe Abschnitt „Apple-/iOS-Kompatibilität als Pflicht“.
- Nach Merge tatsächlichen `main`-Commit und Post-Merge-CI prüfen. Nicht aus einem erfolgreichen PR-Lauf auf den Zustand des Merge-Commits schließen.
- Der Nutzer führt lokal `git pull` aus und prüft die App auf seinem Gerät. Keine Geräteprüfung behaupten, solange sie nicht stattgefunden hat.

## Apple-/iOS-Kompatibilität als Pflicht

- **Jede Änderung muss auch unter iOS funktionsfähig bleiben.** iOS ist keine nachgelagerte Portierungsaufgabe. Bei jeder Planung und Implementierung ist zu prüfen, ob Verhalten, UI, Datenzugriff, Berechtigungen, Plugins, Assets und Konfiguration auch auf iPhone/iPad funktionieren.
- Flutter-Code unter `lib/` wird von Android und iOS gemeinsam verwendet. Änderungen daran müssen deshalb ohne unbeabsichtigte Plattformunterschiede funktionieren. Plattformabhängige Implementierungen sind ausdrücklich für beide Plattformen zu prüfen.
- Bei Änderungen an `ios/**`, `lib/**`, `assets/**`, `pubspec.yaml`, `pubspec.lock` oder am iOS-Workflow muss ein erfolgreicher iOS-Build für den aktuellen PR-Head vorliegen. Dieser Build ist neben Analyze und Tests ein verpflichtender PR-Check.
- Der Workflow **„iPhone simulator smoke test“** baut die iOS-Simulator-App und installiert/startet sie in einem iPhone-Simulator. Er ist ein zusätzlicher Laufzeittest, aber **kein allgemeines Merge-Gate**. Er soll gezielt bei iOS-spezifischen Änderungen, Änderungen an nativen Plugins/Berechtigungen/Plattformkonfiguration sowie vor Releases ausgeführt werden. Ein Simulatorlauf bei jeder Flutter- oder UI-Änderung ist nicht erforderlich.
- **Merge-Gate:** Für jeden PR müssen die verpflichtenden Checks (Repository-Hygiene, `flutter analyze`, `flutter test` und iOS-Build) für exakt den aktuellen PR-Head erfolgreich sein. Ein fehlgeschlagener oder fehlender gezielter Simulator-Smoke-Test blockiert den Merge nicht automatisch; wenn er aufgrund einer iOS-spezifischen Änderung oder eines konkreten Risikos ausgeführt wurde, müssen seine Ergebnisse vor dem Abschluss bewertet werden.
- Änderungen an Supabase-Schema, RPCs, Edge Functions oder sonstigen Backend-Verträgen müssen zusätzlich auf iOS-Kompatibilität geprüft werden: verwendete Tabellen, Spalten, RPC-Parameter/-Antworten, Authentifizierung und Datenformate müssen mit dem gemeinsam genutzten Flutter-Client kompatibel bleiben. Ein Simulator-Build allein beweist keine Backend-Kompatibilität.
- Bei nativen iOS-Funktionen sind die betroffenen Plattformdateien und Einstellungen gezielt zu prüfen, insbesondere `Info.plist`, Berechtigungsbeschreibungen, URL-Schemes, Entitlements, Deployment Target, Plugin-Integration und erforderliche Xcode-Konfiguration. Keine Android-Konfiguration ungeprüft als iOS-Ersatz übernehmen.
- Neue oder geänderte Plugins und native Abhängigkeiten müssen auf iOS-Unterstützung und erforderliche Pod-/Xcode-Schritte geprüft werden. Lockfile und iOS-Projektintegration müssen zusammenpassen.
- Der Simulator-Workflow ist ein Build-/Start-Smoke-Test, kein vollständiger UI-, Hardware- oder Release-Test. Keine Prüfung auf echtem iPhone/iPad, Signierung, TestFlight oder App-Store-Verteilung behaupten, solange sie nicht tatsächlich durchgeführt wurde. Release-/Store-Arbeiten bleiben außerhalb des normalen Entwicklungsworkflows.

## PR-Reihenfolge und Merge-Gates

- Vor jeder Änderung den aktuellen `main`-Commit, alle offenen PRs, ihre Basis-/Head-Commits, Merge-Konflikte und die neuesten CI-Läufe direkt bei GitHub prüfen. Statusangaben aus älteren Chats oder dieser Datei sind kein Live-Nachweis.
- Ältere PRs zuerst prüfen und nach Möglichkeit zuerst abschließen. Die Nummer bzw. das Alter allein entscheidet nicht: Abhängigkeiten, überlappende Dateien und die Basis-Commits sind ausschlaggebend.
- PRs, die auf Änderungen eines anderen offenen PRs aufbauen, erst nach dessen Merge integrieren oder die Abhängigkeit ausdrücklich sauber abbilden. Keine abhängigen PRs so behandeln, als wären sie unabhängig.
- Vor jedem Merge müssen alle für den aktuellen Head-Commit erforderlichen CI-Checks erfolgreich sein und der PR mergebar sein. Bei roten Checks Logs lesen, Ursache beheben und die neuen Läufe abwarten. Nicht wegen Zeitdruck überspringen.
- Zusätzlich gilt das iOS-Merge-Gate aus „Apple-/iOS-Kompatibilität als Pflicht“: Bei iOS-relevanten Änderungen muss der iPhone-Simulator-Workflow für exakt den aktuellen PR-Head erfolgreich sein. Allgemeine Flutter-/Android-Checks reichen dafür nicht aus.
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
- Beide Post-Merge-CI-Workflows wurden für diesen Commit erfolgreich ausgeführt.
- Supabase-Live-Status und Geräteverhalten wurden nicht geprüft.

## Rezeptfilter: Auswahl sichtbar halten und Icons ausrichten (2026-11-23)

- Das linke Filtermenü für Ernährungsart/Hauptzutat aktualisiert die Auswahl sofort, hält das Menü aber weitere 200 ms geöffnet. Die neue Markierung mit Häkchen bleibt dadurch kurz sichtbar, bevor sich das Menü schließt.
- Der rechte Rezeptartfilter verwendet jetzt dieselbe helle Menükarte, abgerundete Auswahlflächen, dezente Kontur und ausgewählte Markierung wie der linke Filter.
- Das linke Filter-Icon ist visuell um 12 px nach rechts versetzt. Der rechte Filter bleibt an seiner bisherigen Position; dadurch wird der Abstand zwischen den Symbolen kleiner.
- Regressionstest in `test/regression/saved_recipes_menu_test.dart` sichert Verzögerung, Icon-Versatz und Menügestaltung ab.
- PR/CI und Geräteprüfung stehen noch aus.

## Rezeptfilter: einheitliche Auswahl und Reset beim Verlassen (2026-11-23)

- Der rechte Rezeptartfilter verwendet jetzt exakt dasselbe Interaktionsmuster wie der linke Hauptzutatenfilter: transparente Material-Hover-/Highlight-Zustände, sofortige eigene Auswahlmarkierung mit Häkchen und automatisches Schließen nach 200 ms.
- Beim Verlassen des Rezepte-Tabs werden Hauptzutaten- und Rezeptartfilter zurückgesetzt. Beim erneuten Öffnen erscheinen dadurch wieder alle gespeicherten Rezepte. Das gilt auch für Navigation über Heute, Einkauf, Profil und die Zurück-Navigation.
- Regressionstests sichern das einheitliche Menüverhalten und den Reset beider Filter ab.
- PR/CI und Geräteprüfung stehen noch aus.

## Foto-Rezeptimport: ausschließlich echten Datei-Download ausgeben (2026-11-23)

- Anlass: Beim Fotoimport wurde statt eines Datei-Anhangs eine Python-Dictionary-Darstellung direkt im Chat ausgegeben. Das ist weder gültiges JSON noch der gewünschte Download-Workflow.
- `buildPhotoImportPrompt` verlangt jetzt ausdrücklich, `together_recipe.json` als echte UTF-8-Datei mit einem Datei-/Python-Werkzeug zu erzeugen und als gültiges JSON zu serialisieren.
- Interne Variablen, Python-Code, Python-Dictionary-Ausgaben und Rezeptdaten dürfen nicht im Chat erscheinen. Nach erfolgreicher Erstellung soll die Chatantwort nur eine kurze Bestätigung und den anklickbaren Download-Anhang enthalten.
- Wenn keine echte Datei erstellt/angehängt werden kann, darf ChatGPT nicht auf Code oder Rezeptdaten im Chat ausweichen, sondern muss die technische Einschränkung kurz melden.
- Regressionstest prüft den Download-only-Vertrag und die expliziten Verbote der sichtbaren Python-Darstellung.
- PR #455 wurde nach vollständig grünen Pflichtprüfungen (Flutter Quality Gate mit iOS Build und Quality Gate mit Analyze/Tests) per Squash-Merge integriert. Merge-Commit auf `main`: `c6d393f519baac9d608228b41e19e3dc4afe43fd`.
- Die Post-Merge-Workflows auf `main` wurden gestartet; ihren Abschluss/Erfolg vor einer Erledigt-Meldung prüfen. Ein echter Test mit ChatGPT-Fotoimport und Geräteprüfung stehen weiterhin aus.

## Rezepteditor: Ernährungs-Dropdown an Rezeptfilter angleichen (2026-11-23)

- Das Mehrfachauswahl-Dropdown „Ernährungsart / Hauptzutat“ im Rezepteditor verwendet jetzt dieselben goldenen Symbole wie der Hauptzutatenfilter: Schwein, Rind, Huhn, Vegetarisch und Fisch.
- Die Einträge sind in derselben Reihenfolge wie im Filter angeordnet. Ausgewählte Einträge erhalten rechts ein grünes Häkchen und dieselbe hellgrüne Hervorhebung/Schriftfarbe; die quadratischen Checkbox-Symbole entfallen.
- Mehrfachauswahl und die bestehende Exklusivregel für „Vegetarisch“ bleiben unverändert.
- Regressionstest in `test/regression/add_recipe_page_visual_test.dart` prüft Symbole, Häkchen und das Fehlen der Checkboxen.
- PR/CI und Geräteprüfung stehen noch aus.

## Optionale Menüplanung auf der Heute-Seite (2026-11-23)

- Eigenständiger Feature-Branch `feature/today-multi-course-menu`; die bisherige Heute-Seite auf `main` bleibt unverändert und kann durch Schließen des PRs unangetastet bleiben.
- Nach Auswahl eines Hauptgerichts lässt sich über „Vorspeise oder Nachtisch ergänzen“ ein Menü bearbeiten. Beide Gänge bleiben optional und können wieder entfernt werden.
- Die Menüauswahl wird als versionierte JSON-Metadaten in `personal_today_plans.decision_value` gespeichert; bestehende Restaurantentscheidungen verwenden das Feld weiterhin unabhängig. Es ist keine Datenbankmigration erforderlich.
- Die Heute-Karte zeigt ausgewählte Zusatzgänge unter dem Hauptgericht und bietet „Menü bearbeiten“.
- Vorspeise/Nachtisch werden aus den gespeicherten Rezepten gewählt. Eine gemeinsame aggregierte Einkaufsliste und ein zeitlich sortierter Kochplan sind noch nicht Teil dieses ersten Ausbauschritts.
- Regressionstest für das Lesen der Menü-Metadaten: `test/data/models/today_plan_menu_test.dart`.
- CI, Code-Review und Gerätetest stehen noch aus. Nicht mergen, bevor Pflicht-CI vollständig grün ist.

## Heute-Seite: Ergebniskarte an Bildschirmhöhe anpassen (2026-11-23)

- Rückmeldung nach PR #457 mit Android-Screenshots: Die Heute-Ergebniskarte lief bei einem Hauptgericht um 20 px über; bei Vorspeise und Nachtisch war die Karte am unteren Rand abgeschnitten.
- Die Ergebniskarte verwendet jetzt eine an der verfügbaren Gerätehöhe orientierte Höhe statt der bisherigen festen Basis plus pauschalen 156 px für Zusatzgänge. So bleibt der Inhalt innerhalb der Karte und die flexible Inhaltsfläche nimmt den verbleibenden Raum auf.
- Oberer und unterer Scroll-Außenabstand sind auf jeweils 18 px vereinheitlicht, damit die Karte mit gleichem Abstand zum AppBar-Bereich und zur unteren Navigation sitzt.
- Regressionstests für die viewportabhängige Kartenhöhe aktualisiert; zwei bestehende Layouttests waren noch auf die frühere feste Höhenfunktion festgelegt und wurden entsprechend angepasst.
- Feature-Branch: `fix/today-menu-card-overflow`. Pflicht-CI und erneuter Android-Gerätetest stehen aus.

## Heute-Seite: einheitliche Kartenhöhe und kompakter Menüinhalt (2026-11-23)

- Auswahlkarte und Ergebniskarte verwenden dieselbe responsive Höhenfunktion `_todayDecisionCardHeight(context)`; Kochen, Bestellen, Essen gehen und die noch offene Auswahl haben damit dieselbe äußere Kartenhöhe.
- Auf der Ergebniskarte skaliert der Inhalt auf kleineren Displays kompakter: Rezeptbild, Rezeptname, Zusatzgangzeilen und Menü-Bearbeiten-Aktion werden angepasst. Es wird ausdrücklich kein Scrollbereich ergänzt.
- Die Aktionsleiste bleibt außerhalb des flexiblen Inhaltsbereichs und vollständig sichtbar.
- Regressionstests für identische Kartenhöhen und die kompakte Darstellung aktualisiert.
- PR #459: Die erste CI-Runde deckte zwei veraltete Regressionserwartungen an die frühere Kartenhöhe/Bildhöhe auf; diese Tests wurden aktualisiert. Neue Pflicht-CI läuft. Kein Geräte-/Simulator-Test durchgeführt.

## Heute-Seite: Aktionsleiste um 15 px verkleinern (2026-11-24)

- Rückmeldung vom Android-Gerät: Die Ergebniskarte mit Hauptgericht, Vorspeise und Nachtisch lief trotz PR #459 noch 11 px über.
- Die untere Aktionsleiste „Teilen“/„Entfernen“ wird von 58 px auf 43 px reduziert. Beide Schaltflächen erhalten kompakte vertikale Abstände, kompakte VisualDensity und eine explizite Mindesthöhe von 43 px; die Trennlinie passt sich ebenfalls an.
- Dadurch werden genau 15 px zusätzlicher vertikaler Platz im Karteninhalt frei, ohne Scrollbereich und ohne die Kartenhöhe zu verändern.
- Regressionstest prüft Footerhöhe, Button-Mindesthöhe und kompakte Touch-Target-Konfiguration.
- Die CI-Runden fanden zwei veraltete 58-Pixel-Erwartungen im Regressionstest `restaurant_decision_completion_and_card_layout_test.dart` (Footerhöhe und Trennlinie); beide auf 43 Pixel aktualisiert.
- PR/CI und erneuter Android-Gerätetest stehen aus.

## Heute-Seite: Menükarte, Auswahlzentrierung und Rezeptdetails (2026-11-24)

- Die Aktion „Menü bearbeiten“ sitzt als Stift-Schaltfläche oben rechts im Kopf der Heute-Ergebniskarte. Dadurch entfällt die zusätzliche Aktionszeile unter den Gängen.
- Vorspeise und Nachtisch werden mittig unter dem Hauptgericht mit größerem Abstand dargestellt. Beide Gangzeilen sind anklickbar und öffnen über ihre gespeicherte `recipe_id` die jeweilige `RecipeDetailPage`; Rückkehr lädt den Heute-Plan erneut.
- Bei Bestell- und Restaurantentscheidungen wird die gewählte Kategorie im flexiblen Bereich zwischen Untertitel und Kartenfuß vertikal zentriert. Die Kochansicht bleibt unverändert.
- Bolt Food verwendet ein stabiles natives Textlogo statt des zuvor fehleranfälligen externen SVG-Abrufs. Beim Öffnen wird ein Fehler eines optionalen App-URL-Schemas abgefangen und anschließend die Webadresse versucht; fehlgeschlagene Webaufrufe zeigen eine verständliche Meldung.
- Regressionstests wurden für die Kartenstruktur und die klickbaren Gänge erweitert. Pflicht-CI und Geräteprüfung stehen noch aus.

## Vollständige Menüauswahl (2026-11-24)

- Der Menüeditor stellt Hauptgericht, Vorspeise und Nachtisch in gleichartigen Rezept-Auswahlkarten dar. Das Hauptgericht ist ein Pflichtgang und kann wie die optionalen Gänge aus den gespeicherten Rezepten ersetzt werden.
- Beim Speichern eines geänderten Hauptgerichts wird der bestehende datumsbezogene persönliche Plan über `set_personal_plan_for_date` aktualisiert; dadurch wird die vorhandene Rezept-Einkaufsliste gemäß der bestehenden RPC-Logik synchronisiert. Anschließend werden die optionalen Menü-Gänge wieder als versionierte Metadaten gespeichert.
- Nach Bestätigung der Personenzahl bei der Auswahl eines Rezepts fragt die App, ob eine Vorspeise oder ein Nachtisch ergänzt werden soll. Bei Zustimmung öffnet sich der Menüeditor; bei Ablehnung geht der bisherige Auswahlablauf weiter. Gemeinsame Entscheidungsanfragen bleiben unverändert.
- Regressionstests prüfen die drei auswählbaren Gänge sowie den zusätzlichen optionalen Abfrageschritt.
- PR/CI und Geräteprüfung stehen noch aus.

## Menüimport und Menüeditor: Dialog und Kartenlayout (2026-11-24)

- Auch der direkte Ablauf „mit ChatGPT erstelltes Rezept importieren und beim Speichern für Heute festlegen“ fragt nach dem Speichern des persönlichen Plans, ob Vorspeise und/oder Nachtisch ergänzt werden sollen. Bei Zustimmung öffnet sich derselbe Menüeditor; bei Ablehnung läuft der Importabschluss normal weiter. Der bestehende Ablauf über „Für heute auswählen“ in der Rezeptsammlung bleibt ebenfalls erhalten.
- Der Dialogtitel „Menü ergänzen?“ ist zentriert. „Nein, danke“ und „Menü zusammenstellen“ stehen untereinander linksbündig.
- Im Menüeditor bleibt die Rezeptauswahl scrollbar; „Menü speichern“ sitzt als fester Footer mit kleinem Abstand direkt oberhalb der unteren Navigation.
- Wenn ein Heute-Plan ausschließlich aus einem Hauptgericht besteht, wird der Rezeptname im freien Inhaltsbereich der Heute-Karte vertikal zentriert. Sobald Zusatzgänge vorhanden sind, bleibt deren bisherige gemeinsame Darstellung erhalten.
- Regressionstests und Pflicht-CI für diese Folgeänderung stehen aus; Android-Geräteprüfung nach Merge erforderlich.

## Tagesentscheidung auf der Heute-Karte bearbeiten (2026-11-24)

- Das Stiftsymbol oben rechts auf der Ergebnis-Tageskarte ist nicht mehr auf Koch-/Rezeptentscheidungen beschränkt.
- Bei „Wir bestellen“ öffnet es erneut den Bestellmodus; bei „Wir gehen essen“ erneut den Restaurantmodus. Die jeweilige Auswahl läuft über den bestehenden datumsbezogenen Auswahlablauf und aktualisiert anschließend die Heute-Karte.
- Bei Rezept-/Kochentscheidungen öffnet es weiterhin den Menüeditor, damit Hauptgericht und optionale Gänge bearbeitet werden können.
- Regressionstests prüfen die Zuordnung der Entscheidungstypen und die sichtbare Bearbeiten-Aktion.
- PR/CI und Android-Geräteprüfung stehen noch aus.

## Bestehende Tagesentscheidungen ausdrücklich bearbeiten (2026-11-24)

- Ursache der Meldung „Dieser Tag ist bereits verplant“: Die Live-RPC `set_personal_plan_for_date` wurde durch Migration `20261012100000_prevent_overwriting_planned_days` absichtlich so geändert, dass sie bei jedem bereits belegten persönlichen Tag mit „Dieser Tag ist bereits verplant“ abbricht. Der Menüeditor und die Bearbeiten-Aktion verwendeten bisher denselben RPC wie eine neue Planung.
- Normale Neuauswahl bleibt weiterhin gegen versehentliches Überschreiben geschützt. Für die explizite Bearbeiten-Aktion gibt es jetzt den separaten RPC `replace_personal_plan_for_date`. Er verlangt eine bereits vorhandene persönliche Entscheidung des angemeldeten Nutzers, sperrt den Datensatz während der Änderung, erhält dessen Plan-ID und synchronisiert die Rezept-Einkaufsliste.
- Der Menüeditor verwendet den Ersatz-RPC nur dann, wenn das Hauptgericht tatsächlich geändert wird. Bestell- und Restaurantbearbeitung geben den expliziten Bearbeitungsmodus durch die Navigation bis zur Speicherung weiter. Normale Auswahlabläufe verwenden weiterhin die bisherigen geschützten RPCs.
- Gemeinsame Essenspläne bleiben als Sperrgrund erhalten. Der Ersatz-RPC kann weder einen Tag ohne persönliche Entscheidung anlegen noch einen gemeinsamen Plan überschreiben.
- Neue Regressionstests prüfen die explizite Ersatzroute für Hauptgericht, Bestellung und Restaurant sowie die Datenbank-Schutzbedingungen.
- Neue Migration: `20261124170000_replace_existing_personal_decision.sql`. Sie muss auf Supabase-Projekt `oidxezjdwqktpxuypbfb` angewendet und anschließend durch einen Test der RPC-/Schema-Definition verifiziert werden.
- Branch `fix/edit-existing-today-decisions`; PR und CI stehen noch aus. Kein Merge ohne vollständige Pflicht-CI. Android-Gerätetest nach Merge erforderlich.

## Rezeptbearbeitung: Verfügbarkeitsprüfung an Rezeptsammlung angleichen (2026-11-24)

- Ursache der Meldung „Dieses Rezept ist nicht mehr verfügbar“ beim Ändern des Hauptgerichts: Live-Postgres-Logs vom 24.11.2026 um 17:22:31 und 17:23:50 UTC zeigen den Fehler in der Funktion replace_personal_plan_for_date (PL/pgSQL-Zeile 24). Die Funktion verlangte zusätzlich zu einer existierenden Rezept-ID entweder recipes.created_by = auth.uid() oder einen Eintrag in recipe_saves.
- Der Rezeptauswahldialog lädt dagegen die sichtbare Rezeptsammlung direkt aus recipes über RecipeRepository.savedRecipeModels(). Damit konnte ein Rezept auswählbar sein, obwohl es die zusätzliche, engere Datenbankprüfung nicht erfüllte.
- Migration 20261124183000_align_recipe_edit_availability.sql passt die Prüfung an: Für die explizite Bearbeitung muss das Rezept in recipes existieren; Anmeldung, gültige Rezept-ID, Personenzahl, bestehender persönlicher Plan und Schutz gemeinsamer Pläne bleiben geprüft.
- Migration wurde auf Supabase-Projekt oidxezjdwqktpxuypbfb live angewendet. Verifiziert: kein zusätzliches recipe_saves-Erfordernis, Existenzprüfung aktiv, EXECUTE für authenticated erlaubt und für anon gesperrt.
- Regressionstest test/regression/recipe_edit_availability_test.dart ergänzt.
- Branch fix/recipe-availability-edit-validation; PR und CI stehen noch aus. Android-Gerätetest nach Merge erforderlich.

## Rezeptbearbeitung: RLS für Menü-Metadaten angleichen (2026-11-24)

- Neuer Live-Fehler „Keine Berechtigung für diese Aktion“ nach erfolgreichem Rezeptwechsel: Postgres-Logs zeigen, dass `replace_personal_plan_for_date` mit HTTP 200 erfolgreich war. Anschließend scheiterte ein separater REST-UPDATE auf `personal_today_plans.decision_value` mit SQLSTATE 42501 („new row violates row-level security policy“).
- Ursache: Die UPDATE-Policy verlangte weiterhin `recipes.created_by = auth.uid()` oder einen `recipe_saves`-Eintrag. Das blockierte die Metadatenänderung für ein Rezept, das bereits über die validierte Bearbeitungs-RPC dem persönlichen Plan zugeordnet und dadurch für den Nutzer sichtbar war.
- Die UPDATE-Policy prüft jetzt Eigentümerschaft des Plans und dass das zugeordnete Rezept über die bestehende Rezept-Sichtbarkeits-Policy lesbar ist. Die strengere INSERT-Policy bleibt unverändert; Rezeptwechsel selbst läuft weiter über `replace_personal_plan_for_date`.
- Migration `20261124184500_allow_visible_recipe_plan_metadata_updates.sql` wurde auf Supabase `oidxezjdwqktpxuypbfb` live angewendet. Schema-/Policy-Definition anschließend prüfen; Regressionstest und CI laufen über PR #466.

## Restaurantadresse auf der Heute-Entscheidungskarte (2026-11-24)

- Bei der Entscheidung „Heute essen gehen“ zeigt die Karte unter dem Restaurantnamen zusätzlich die Straße und den Ort aus den gespeicherten Restaurantdaten.
- Die Adresszeilen sind kleiner und dezenter als der Restaurantname gestaltet. Name und Adresse werden als gemeinsamer Inhaltsblock in der verfügbaren Fläche zwischen Küchenrichtung und Aktionsleiste vertikal zentriert.
- Bei fehlenden Adressfeldern werden nur vorhandene Zeilen angezeigt; andere Entscheidungstypen bleiben unverändert.
- Regressionstest in `test/regression/today_decision_card_layout_test.dart` erweitert.
- Branch `feat/today-restaurant-address-card`; PR/CI stehen noch aus. Kein Merge ohne vollständige Pflicht-CI. Android-Gerätetest nach Merge erforderlich.

## Restaurantadresse immer einzeilig darstellen (2026-11-24)

- Die Adresszeile auf der Heute-Restaurantkarte verwendet jetzt `FittedBox(fit: BoxFit.scaleDown)` mit nicht umbrechendem Text und einer Zeile.
- Lange Straßen-/Ortsangaben werden dadurch proportional verkleinert, bis sie in die verfügbare Kartenbreite passen; das bisherige Abschneiden mit Auslassungspunkten entfällt.
- Name und Adresse bleiben als gemeinsamer Block vertikal zentriert. Regressionstest prüft die Skalierungs- und Einzeilen-Konfiguration.
- Branch `fix/fit-restaurant-address-single-line`; PR/CI stehen noch aus. Kein Merge ohne vollständige Pflicht-CI. Android-Gerätetest nach Merge erforderlich.

## Icons für Rezeptarten-Filter (2026-11-27)

- Der Filter „Nach Rezeptart“ zeigt für „Alle Rezeptarten“ dasselbe goldene Raster-Icon wie der Hauptzutatenfilter.
- Jede Rezeptart hat ein eigenes goldenes Icon: Hauptgericht (Besteck), Süßspeise (Kuchen), Beilage (Teller), Salat (Blatt), Suppe (Suppenschüssel), Snack (Fast Food) und Frühstück (Kaffee).
- Filterlogik, Auswahlzustand und Beschriftungen bleiben unverändert; angepasst wurde nur die visuelle Kennzeichnung.
- Regressionstest `test/regression/recipe_category_filter_icons_test.dart` prüft alle Icons und die Goldfarbe.
- Branch `feat/recipe-category-filter-icons`; PR/CI ausstehend. Kein Merge ohne vollständige Pflicht-CI.

## Rezeptauswahl im Koch-Flow vereinheitlicht (2026-11-27)

- Die Auswahl aus „Wir kochen“ verwendet jetzt dieselbe Rezeptkarten-Komponente/-Darstellung wie „Meine Rezepte“: gleiches Kartenmaß, Bildgröße, Titel, Kategorie/Zutaten-Tags und Aktionszeile.
- Die beiden Filter (Hauptzutat und Rezeptart) sowie die Suche sind auch im Auswahlmodus verfügbar und sehen identisch aus.
- Der Auswahlmodus ändert nur die Auswahlaktion („Für heute auswählen“ bzw. „Für diesen Tag auswählen“); Filter und Rezeptdarstellung bleiben einheitlich.
- Während die Rezeptliste geladen wird, zeigt die Seite den Ladeindikator statt fälschlich „Kein passendes Rezept gefunden“. Der Leerzustand erscheint erst nach abgeschlossenem Laden.
- Regressionstest in `test/regression/saved_recipes_today_selection_test.dart` erweitert.
- Branch `fix/unify-saved-recipe-selection-ui`; PR/CI ausstehend. Kein Merge ohne vollständige Pflicht-CI.

## Nicht unterbrechbare Bearbeitungspfade (2026-11-27)

- Neue zentrale Steuerung `lib/core/flow_guard.dart`: ein aktiver Pfad, keine Wiederaufnahme/Drafts. `beginIfIdle` verhindert, dass verschachtelte Schritte den bestehenden Pfad überschreiben; `complete` beendet ihn nach erfolgreicher Speicherung; bestätigtes Verlassen beendet ihn endgültig.
- Die untere Navigation (Heute, Rezepte, Einkauf, Profil) fragt vor jedem Tabwechsel, der den aktiven Pfad verlassen würde. Erst nach ausdrücklicher Bestätigung wird der interne Navigationsstapel zurückgesetzt und der Ziel-Tab geöffnet.
- `FlowExitGuard` registriert jetzt die Route des ersten Flow-Schritts als Wurzel. Weitere geschützte Seiten desselben Pfads bleiben intern normal rückwärts navigierbar; nur das Verlassen der tatsächlichen Wurzel fragt nach Bestätigung.
- Die System-Zurück-Behandlung im AppShell wickelt zunächst verschachtelte Routen ab und fragt erst an der Wurzel nach dem Verlassen des aktiven Pfads.
- Angebundene Pfade: Kochen/Bestellen/Essen gehen für heute, Überraschungsroulette mit Übergabe an den ausgewählten Modus, gemeinsame Entscheidungsanfrage, persönliche Rezeptüberraschung, Rezeptauswahl aus „Meine Rezepte“ für heute sowie direkte Menübearbeitung auf der Heute-Seite.
- Erfolgreiche Auswahl/Speicherung beendet den Pfad; ein Abbruch im Bestätigungsdialog lässt ihn unverändert aktiv. Es werden keine Zwischenschritte für eine spätere Fortsetzung gespeichert.
- Regressionstest `test/regression/flow_guard_test.dart` prüft den zentralen Zustand, Bestätigen/Ablehnen, den Schutz der Wurzel und normale Navigation über interne Kindseiten. `global_navigation_persistence_test.dart` prüft die Absicherung der unteren Navigation.
- Branch `feat/guarded-editing-paths`; PR #471. Pflicht-CI für den aktuellen PR-Head erneut ausführen und vollständig abwarten; kein Merge ohne Repository-Hygiene, Analyze, Tests und iOS-Build. Android-Gerätetest bleibt nach Merge erforderlich.
