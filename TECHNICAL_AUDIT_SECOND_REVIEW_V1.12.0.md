# TECHNICAL_AUDIT_SECOND_REVIEW_V1.12.0

## 1. Executive Summary

Diese Zweitprüfung wurde unabhängig gegen das tatsächlich gelieferte ZIP `Schmackofatz_v1.12.0_recipe_sharing_technical_audit_optimized.zip` sowie gegen das aktuell verbundene Supabase-Projekt `oidxezjdwqktpxuypbfb` durchgeführt.

### Ergebnis in Kurzform

- Die **AsyncController-Härtung ist technisch sinnvoll und korrekt implementiert**: ein älterer Request darf weder Daten noch Fehler noch den Loading-Abschluss eines neueren Requests überschreiben.
- Der vorhandene Async-Regressionstest war **nur teilweise ausreichend**. Er reproduzierte den zentralen Stale-Response-Fall, prüfte aber die Dispose-Situation nicht wirklich und deckte einen stale Fehler gegen einen neueren Erfolg nicht ab. Der Test wurde deshalb erweitert.
- Die beiden behaupteten FK-Indizes **existieren live auf den korrekten Spalten**. Die neue lokale Migration dafür ist jedoch **nicht Teil der aktuell angewendeten Supabase-Migrationshistorie**. Die Indizes sind physisch vorhanden, die Deployment-/Reproduzierbarkeitshistorie bleibt dadurch inkonsistent.
- Die Supabase-RLS-Struktur ist überwiegend ownership-/membership-basiert und die geprüften `SECURITY DEFINER`-Funktionen enthalten Autorisierungsprüfungen. Gleichzeitig sind viele dieser Funktionen bewusst als RPC-Endpunkte für `authenticated` exponiert. Der Advisor meldet sie deshalb als Warnung, was für sich genommen noch keine Sicherheitslücke beweist.
- Es gibt einen **konkreten Race-Condition-Risikopunkt in `join_connection()`**: Die Funktion prüft die Mitgliederzahl vor dem Insert, ohne die Connection-Zeile für die konkurrierenden Joins zu sperren. Zwei parallele Joins können dadurch theoretisch eine Drei-Personen-Connection erzeugen. Das ist ein Datenintegritätsproblem und sollte vor produktiver Skalierung behoben werden.
- Die Realtime-Implementierung entfernt Channels korrekt, verwendet aber an mehreren Stellen **unbegrenzte Table-Subscriptions** und löst danach komplette Reloads aus. Das ist aktuell eher ein Performance-/Skalierungsproblem als ein Security-Problem.
- Das Projekt enthält **61 lokale SQL-Migrationen**, während die Live-Datenbank **38 angewendete Migrationseinträge** meldet. Die Versionen/Namen sind nicht 1:1 identisch. Das ist das größte Reproduzierbarkeitsrisiko des aktuellen Stands.
- Die lokale Asset-Menge beträgt rund **67 MB**, davon etwa **55,5 MB allein für Hintergrundbilder**. Mehrere einzelne PNGs liegen bei ca. 2,3–2,8 MB. Das ist ein realer P2-Performance-/Downloadkostenpunkt, aber kein Grund für einen riskanten Sofortumbau.
- Flutter/Dart sind in der Audit-Umgebung **nicht installiert**. Daher wurden `flutter analyze`, `flutter test`, Coverage und Builds nicht ausgeführt und werden ausdrücklich nicht als erfolgreich bewertet.

## 2. Prüfgrundlage

### Projekt

- Flutter-Projekt mit 71 Dart-Dateien unter `lib/`
- 63 Testdateien
- keine `integration_test/`-Tests
- `pubspec.yaml` Version `1.12.0+211`
- kein Git-Repository im gelieferten ZIP, daher keine echte Git-Historienrekonstruktion möglich
- 61 SQL-Migrationsdateien im ZIP
- lokale Edge Function `restaurant-discovery`
- `generate-recipes` ist lokal nur noch als deaktivierter Platzhalter dokumentiert

### Live-Supabase

- Projekt: `oidxezjdwqktpxuypbfb`
- Region: `eu-central-1`
- Status: aktiv/gesund
- PostgreSQL 17
- 15 Benutzer, aktuell alle als Anonymous Auth erkennbar
- 15 relevante Public-Tabellen geprüft
- RLS auf den geprüften Public-Tabellen aktiviert
- Realtime-Publication enthält 8 relevante Tabellen
- 38 Migrationseinträge live

## 3. Prüfung des vorherigen Audits

| Behauptung vorheriges Audit | Tatsächlicher Zustand | Bewertung |
|---|---|---|
| AsyncController gegen Race Conditions gehärtet | Generation counter vorhanden; stale Erfolg/Fehler/Loading werden ignoriert | **korrekt** |
| Regressionstest für stale responses ergänzt | Test vorhanden und zentraler Fall wird reproduziert | **teilweise korrekt** |
| Dispose-Verhalten getestet | Alter Test hat nach Dispose nur einen synchronen Load ohne Listener geprüft | **teilweise korrekt** |
| Zwei FK-Indizes hinzugefügt | Beide Indizes live vorhanden und korrekt definiert | **korrekt** |
| FK-Indizes als Migration reproduzierbar | Lokale Migration vorhanden, live nicht als Migration angewendet | **teilweise korrekt** |
| Supabase Smoke Test erweitert | Smoke-Test prüft AI-Rückbau, SECURITY DEFINER, Personal-Today-RPCs und die Indizes | **korrekt, aber begrenzt** |
| Security geprüft | RLS, SECURITY DEFINER und Auth wurden geprüft; zusätzliche Datenintegritätsrisiken bleiben | **teilweise korrekt** |
| Realtime geprüft | Channels werden überwiegend sauber entfernt; mehrere Subscriptions sind unfiltered/full-reload-lastig | **teilweise korrekt** |
| Architektur sei ausreichend stabil | Grundstruktur ist brauchbar, aber mehrere große Feature-Dateien bleiben stark gekoppelt | **nicht als „behoben“ nachweisbar** |
| Flutter-Tests erfolgreich | In dieser Umgebung nicht ausführbar | **nicht verifizierbar** |

## 4. AsyncController

### Aktuelle Implementierung

`lib/core/controllers/async_controller.dart` verwendet `_loadGeneration`.

Ablauf:

1. Jeder `load()` erhöht die Generation.
2. Nur die aktuellste Generation darf `_data` setzen.
3. Nur die aktuellste Generation darf `_error` setzen.
4. Nur die aktuellste Generation darf `_loading=false` setzen und benachrichtigen.
5. Nach `dispose()` werden Notifications zusätzlich durch `_disposed` unterdrückt.

### Szenarien

#### A: A startet, B startet, B beendet sich zuerst, A später

**Erwartetes Verhalten:** B bleibt maßgeblich.

**Befund:** korrekt. A darf wegen `generation != _loadGeneration` weder Daten noch Loading-State überschreiben.

#### B: A schlägt fehl, B ist erfolgreich

**Befund:** korrekt. Ein Fehler aus A wird verworfen, wenn B die aktuelle Generation ist.

#### C: Widget wird während eines Requests entfernt

**Befund:** Notifications werden nach `dispose()` unterdrückt. Die eigentliche Fetch-Arbeit wird nicht abgebrochen, aber deren Ergebnis darf keinen Listener mehr benachrichtigen.

#### D: Mehrere Requests / Abbruch

Es gibt keinen echten Cancellation-Mechanismus. Die Implementierung verwendet Generation Invalidierung statt physischer Request-Cancellation.

Das ist für die aktuelle Architektur ausreichend, solange `fetch()` keine teuren oder irreversiblen Client-Ressourcen offen hält.

### Bewertung

**P1/P2: kein aktueller Funktionsfehler im Generation-Mechanismus.**

Der verbleibende Punkt ist fehlende echte Cancellation. Das sollte nicht nur aus Prinzip ergänzt werden, weil dafür jede Repository-Operation eine Cancellation-Strategie bräuchte.

## 5. Regressionstest

Der ursprüngliche Test reproduzierte bereits den wichtigen Stale-Response-Fall.

Schwäche:

- Dispose-Test hatte keinen Listener.
- Der Test startete nach `dispose()` einen sofort erfüllten Load und prüfte damit nicht, ob eine tatsächlich verspätete Antwort eine Notification auslöst.
- stale Fehler gegen neuen Erfolg fehlte.

### Umgesetzte Verbesserung

`test/core/async_controller_test.dart` wurde erweitert um:

1. echten In-Flight-Dispose-Test mit `Completer`
2. Listener-Assertion gegen Notifications nach Dispose
3. stale Fehler gegen neueren erfolgreichen Request

Der vorhandene Stale-Success-Test wurde außerdem sprachlich präzisiert.

**Flutter-Testlauf konnte nicht ausgeführt werden, da Flutter/Dart fehlen.**

## 6. Supabase-Indizes

Live vorhanden:

```text
idx_personal_decision_history_plan_id
  -> public.personal_decision_history(plan_id)

idx_personal_today_plans_recipe_id
  -> public.personal_today_plans(recipe_id)
```

Beide entsprechen den zuvor gemeldeten unindexierten Foreign Keys.

### Bewertung

Die Indizes sind technisch plausibel.

Der Performance Advisor meldet beide derzeit als `unused`. Das ist bei der sehr kleinen Datenmenge und fehlender Produktionslast kein ausreichender Grund für eine Entfernung.

Es gibt außerdem bereits:

- `idx_personal_decision_history_user_created`
- `idx_personal_decision_history_recipe`
- `idx_personal_today_plans_user_date`
- `personal_today_plans_one_active_per_user_day`

Die neuen Indizes sind daher keine offensichtlichen Duplikate.

## 7. RLS

Die geprüften Public-Tabellen haben RLS aktiviert.

Die Ownership-/Membership-Policies sind überwiegend sauber strukturiert:

- Personal-Daten über `auth.uid()`
- Connect-Daten über Membership
- Rezeptzugriff über Owner/Saved/Shared/Suggestion
- Shopping über Personal- oder Shared-Plan
- Notifications über `user_id`
- UPDATE-Policies verwenden dort, wo relevant, sowohl `USING` als auch `WITH CHECK`

### Auffälligkeit

Supabase meldet mehrere `multiple_permissive_policies`:

- `recipe_ingredients` SELECT
- `recipe_suggestions` UPDATE
- `recipes` SELECT/INSERT/UPDATE/DELETE

Das ist primär ein Performance-/Komplexitätsproblem. Es ist nicht automatisch eine Sicherheitslücke, weil die Policies bewusst unterschiedliche Zugriffswege abbilden.

### Shared Recipe Plan

Die UPDATE-Policy erlaubt Connection-Mitgliedern Änderungen, prüft im `WITH CHECK` aber nicht jede einzelne semantische Spalte.

Insbesondere sind direkte Tabellenupdates prinzipiell weniger streng als die dafür vorgesehenen RPCs.

**Empfehlung: P2, später härten.**

Sinnvoll wäre, die direkte UPDATE-Oberfläche auf wirklich veränderbare Felder zu begrenzen oder die Mutation vollständig über autorisierte RPCs zu führen.

## 8. Anonymous Auth

Die Live-Datenbank enthält 15 Benutzer und alle wurden als Anonymous Auth identifiziert.

Die RLS-Policies verwenden `authenticated`, was bei Supabase Anonymous Auth erwartungsgemäß auch anonyme Sessions umfasst.

Das ist deshalb **nicht automatisch ein Fehler**.

Die eigentliche Isolation erfolgt über `auth.uid()` bzw. Connection Membership.

Die Prüfung ergab keine Grundlage für die Behauptung, dass ein anonymer Benutzer allein durch seine Rolle die Daten anderer Benutzer sehen darf.

### Produkt-Risiko

Anonymous Auth bedeutet jedoch:

- Identität hängt an der lokalen Session.
- Verlust der Session kann zur verlorenen Zuordnung zu den bisherigen Daten führen.
- Gerätewechsel erzeugt nicht automatisch dieselbe Identität.
- Eine spätere Account-Migration muss bewusst geplant werden.

Das ist Produkt-/Datenlebenszyklusrisiko, keine unmittelbare RLS-Lücke.

## 9. SECURITY DEFINER

Die geprüften öffentlichen `SECURITY DEFINER`-Funktionen setzen einen eingeschränkten `search_path` und sind für `anon` nicht ausführbar.

Viele sind absichtlich für `authenticated` ausführbar, weil sie als RPC-Endpunkte der Anwendung dienen.

Beispiele mit expliziter Autorisierung:

- `accept_decision_request`
- `cancel_decision_request`
- `create_decision_request`
- `create_recipe_suggestion`
- `join_connection`
- `respond_to_recipe_suggestion`
- `share_recipe_for_today`
- `update_shared_recipe_plan_servings`
- `update_shared_recipe_status`
- `save_recipe_with_ingredients`

### Kritischer Befund

`join_connection()` prüft:

1. aktueller Benutzer hat noch keine Connection
2. Code existiert
3. aktuelle Connection hat weniger als 2 Mitglieder
4. dann INSERT

Zwischen Schritt 3 und 4 fehlt eine Sperre der Connection-Zeile.

Zwei konkurrierende Join-Requests können daher beide eine Mitgliederzahl von 1 sehen und anschließend jeweils einen weiteren Benutzer einfügen.

**Klassifikation: P1 Datenintegrität / Race Condition.**

### Empfohlene Lösung

In `join_connection()` die Connection-Zeile vor der Mitgliederzählung mit `FOR UPDATE` sperren. Dadurch serialisieren sich konkurrierende Joins derselben Connection.

Diese Änderung sollte wegen der bereits auseinanderlaufenden Migrationshistorie zunächst als vorbereitete DB-Änderung behandelt und in einer sauberen Migration committed werden.

## 10. Realtime

Live-Publication:

- `app_notifications`
- `connection_members`
- `decision_requests`
- `personal_today_plans`
- `recipe_saves`
- `recipe_suggestions`
- `shared_recipe_plans`
- `shopping_items`

### Positiv

Die untersuchten Flutter-Seiten entfernen ihre Channels beim Dispose.

### Problem

Mehrere Channels hören auf komplette Tabellen statt auf den eigenen Benutzer/Plan.

Beispiele:

- `TodayPage`: `personal_today_plans` ohne Row-Filter
- `ShoppingListPage`: `connection_members`, `shared_recipe_plans`, `personal_today_plans` ohne Row-Filter
- `SavedRecipesPage`: mehrere komplette Tabellen

Die RLS-Sichtbarkeit bleibt davon getrennt. Das Hauptproblem ist unnötige Event-Verarbeitung und Full Reload.

### Bewertung

**P2 Performance/Skalierung.**

Kein Beleg für einen Datenleck-Bug allein durch diese Subscriptions.

## 11. Race Conditions außerhalb AsyncController

### Shopping

`ShoppingPage.toggleItem()` verwendet Optimistic UI.

A und B können denselben Eintrag gleichzeitig ändern. Die Datenbank ist letztlich last-write-wins.

Der Client rollt bei einem eigenen Fehler auf seinen lokalen alten Zustand zurück. Ein fremdes Realtime-Update kann danach erneut laden.

Das ist für die aktuelle kleine Zwei-Personen-Anwendung akzeptabel, aber nicht konfliktfrei.

**P2**, kein Sofortumbau.

### Shared Recipe

Servings und Status werden über RPCs aktualisiert.

Die RPCs autorisieren Connection-Mitglieder.

Es gibt jedoch keine Version-/Revision-Nummer. Gleichzeitige semantisch unabhängige Änderungen können sich gegenseitig in der UI überholen, obwohl die Datenbanktransaktionen jeweils korrekt sind.

**P2**, später optimieren, falls echte Konflikte beobachtet werden.

### Today

`AsyncController` verhindert stale Load-Responses.

Die zusätzliche `TodayPage.load()`-Schicht übernimmt danach den aktuellen Controller-State. Das reduziert das Risiko eines alten Ergebnisses deutlich.

## 12. Flutter-Code / Architektur

Auffällig große Dateien:

- `lib/features/shared/today_page.dart`: 1113 Zeilen
- `lib/features/recipes/saved_recipes_page.dart`: 841 Zeilen
- `lib/features/recipes/add_recipe_page.dart`: 750 Zeilen
- `lib/features/food_modes/food_mode_page.dart`: 576 Zeilen

Es gibt weiterhin mehrere Feature-Seiten mit direktem Supabase-Zugriff.

Das ist kein akuter Fehler.

Eine Komplettmigration auf Clean Architecture oder einen neuen State-Management-Stack wäre nicht gerechtfertigt.

**P2 Wartbarkeit**, schrittweise Refaktorierung nur bei Feature-Arbeiten.

## 13. Query Audit

Die Queries verwenden überwiegend konkrete Spalten statt pauschalem `select('*')`.

Es wurden keine Queries in `build()` als offensichtliches Hauptproblem gefunden.

Es gibt jedoch mehrere Full Reloads nach Realtime Events.

`Future.wait()` wird bereits sinnvoll verwendet, z. B. im Surprise-Flow für unabhängige Datenquellen.

Kein Anlass für blindes Parallelisieren.

## 14. Async / Disposal

Positiv:

- viele `mounted`-Checks
- `AsyncController` Generation Guard
- Timer in Saved Recipes wird disposed
- Realtime Channels werden entfernt
- Search Controller wird disposed

Verbesserungsbedarf:

- Realtime callbacks können nach Dispose noch `load()` anstoßen, wobei die jeweilige `load()`-Methode anschließend `mounted` prüft. Das verhindert State-Schäden, aber nicht zwingend die unnötige Arbeit.
- Echte Request-Cancellation ist nicht vorhanden.

## 15. Performance / Assets

`assets/` umfasst rund 67 MB.

Allein `assets/together/clean/background/` umfasst etwa 55,5 MB.

Mehrere Hintergrundbilder liegen bei ca. 2,3–2,8 MB.

Das ist ein konkreter P2-Kandidat.

### Empfehlung

Nicht sofort sämtliche Assets neu rendern.

Stattdessen:

1. PNGs nach tatsächlicher Zielauflösung prüfen.
2. Fotohintergründe für verlustbehaftete Kompression bzw. moderne Formate evaluieren.
3. Vorher/Nachher visuell vergleichen.
4. Nur nachweislich überdimensionierte Assets ersetzen.

## 16. Error Handling

Es existieren mehrere bewusste `catch (_) {}`-Stellen, insbesondere bei optionalen Offline-/Nebenpfaden.

Das ist nicht automatisch falsch.

Kritischer sind die Stellen, an denen ein Hauptdatenpfad Fehler verschlucken würde. In den geprüften zentralen Personal-Today-Pfaden werden echte Serverfehler überwiegend weitergereicht.

Kein pauschaler Umbau erforderlich.

## 17. Logging

Im Produktcode wurde nur sehr begrenztes Debug-Logging gefunden.

`debugPrint('[Schmackofatz] $error')` protokolliert keine offensichtlichen Benutzer-IDs oder E-Mail-Adressen.

Kein akuter Logging-Sicherheitsbefund.

## 18. Dependency Audit

Direkte Runtime-Abhängigkeiten sind überschaubar:

- `supabase_flutter`
- `url_launcher`
- `connectivity_plus`
- `shared_preferences`
- `file_picker`
- `cupertino_icons`

Keine unnötige große State-Management-Abhängigkeit.

Die aktuelle `supabase_flutter`-Version ist im Lockfile reproduzierbar gepinnt.

Keine Dependency wurde nur aus Aktualisierungsgründen verändert.

## 19. Migration Audit

### Tatsächlicher Zustand

- ZIP: 61 SQL-Migrationsdateien
- Live: 38 angewendete Migrationseinträge

Die Historien sind nicht 1:1 dieselbe Sequenz.

Die lokale Kette enthält ältere Entwicklungs-/Rekonstruktionsstände, während die Live-Datenbank teilweise neu nummerierte bzw. anders benannte Migrationen verwendet.

Besonders relevant:

`20260922210000_audit_add_missing_fk_indexes.sql` ist lokal vorhanden, aber nicht als Live-Migration gelistet.

Die darin definierten Indizes existieren live trotzdem.

Das zeigt, dass die Schemaänderung physisch angewendet wurde, ohne dass die aktuelle Live-Migrationshistorie denselben Commit widerspiegelt.

### Risiko

**P1/P2 Reproduzierbarkeit und Deployment-Sicherheit.**

Nicht automatisch Datenkorruption.

### Empfehlung

Nicht einfach Migrationen löschen.

Stattdessen einen einmaligen Schema-/Migration-Drift-Abgleich etablieren:

- Live-Schema als Referenz erfassen
- lokale Kette gegen Live-Schema diffen
- historische Migrationen nicht rückwirkend umschreiben
- einen klaren Baseline-/Reconcile-Prozess definieren
- danach neue Migrationen strikt synchron halten

## 20. Edge Functions

### `restaurant-discovery`

Live:

- aktiv
- `verify_jwt=false`
- serverseitige Authentifizierung über `createSupabaseContext(req, { auth: 'user' })`
- Input Validation
- fester 20-km-Radius
- Limit 1–10
- externe Overpass-Endpunkte
- 15-Sekunden Fetch Timeout
- maximal zwei Fallback-Endpunkte

Die Kombination `verify_jwt=false` + serverseitige Auth-Prüfung ist technisch vertretbar, weil die Funktion die Authentifizierung selbst erzwingt.

### Offener Punkt

Es gibt keinen erkennbaren anwendungsbezogenen Rate-Limit-Mechanismus für diese teure externe Suche.

Da Anonymous Auth verwendet wird, sollte die Missbrauchsresistenz beobachtet werden.

**P2**, zunächst Monitoring/Rate-Limit-Strategie prüfen.

### `generate-recipes`

Live aktiv, aber bewusst deaktiviert und liefert HTTP 410.

Das entspricht dem lokalen Projektstand und ist kein aktiver AI-Generierungsweg.

## 21. Testarchitektur

63 Testdateien sind vorhanden.

Es gibt keine `integration_test/`-Tests.

Ein erheblicher Anteil der Regressionstests prüft Source-Fragmente mit `File(...).readAsStringSync()`.

Das ist nützlich als Architektur-/Contract-Schutz, aber kein Ersatz für Verhaltenstests.

Der AsyncController-Test ist ein gutes Beispiel: Nach Erweiterung deckt er echtes asynchrones Verhalten ab.

### Empfehlung

P2:

- zentrale Repository-Tests
- State-/Controller-Tests
- gezielte RLS-Tests mit zwei anonymen Sessions
- Realtime-Integrationstests für kritische Flows

Nicht alle Source-Tests auf einmal ersetzen.

## 22. Supabase Advisor

Security Advisor meldet:

- 20 `SECURITY DEFINER`-Funktionen, die von `authenticated` ausführbar sind
- Anonymous-Auth-Warnungen für die entsprechenden `authenticated`-Policies
- deaktivierten Leaked-Password-Schutz

Die ersten beiden Punkte sind im Kontext dieser Anwendung teilweise erwartbar:

- Anonymous Auth ist bewusst Teil des Produktmodells.
- Viele SECURITY DEFINER-Funktionen sind absichtlich RPC-Endpunkte.

Der Advisor-Befund ist deshalb **kein Beweis für einen Bypass**.

Der Leaked-Password-Schutz ist für eine reine Anonymous-Auth-Anwendung aktuell wenig relevant, sollte aber bei Einführung von Passwort-Login aktiviert werden.

Performance Advisor meldet aktuell 17 unbenutzte Indizes sowie 6 Gruppen mit mehrfach permissiven Policies.

Diese Befunde sind keine ausreichende Begründung für eine aggressive Index-/Policy-Bereinigung.

## 23. Supabase-Verifikation

Durchgeführt:

- Tabellen-/Schema-Inspektion
- RLS-Inspektion
- Policy-Inspektion
- Foreign Keys / Indizes
- SECURITY DEFINER
- EXECUTE-Berechtigungen
- Realtime-Publication
- Trigger
- Auth-User-Verteilung
- Migration History
- Edge Functions
- Security Advisor
- Performance Advisor

Nicht durchgeführt:

- echter Flutter Testlauf
- echter Flutter Analyze-Lauf
- Flutter Build
- reale Zwei-Geräte-Realtime-Simulation
- echter End-to-End-Test mit zwei mobilen Anonymous Sessions

Grund: Flutter/Dart fehlen in der Ausführungsumgebung bzw. für echte Multi-Device-Simulation steht keine zweite laufende App-Instanz zur Verfügung.

## 24. Konkrete Änderungsempfehlungen

### P1: `join_connection()` atomar gegen Parallel-Joins absichern

**Problem:** Zwei parallele Joins können die 2-Personen-Grenze theoretisch überschreiten.

**Ursache:** Mitgliederzählung ohne Lock auf der Connection-Zeile.

**Betroffene Struktur:** `public.join_connection()` / `connection_members`.

**Lösung:** Connection-Zeile `FOR UPDATE` sperren, danach Mitgliederzahl prüfen und insert durchführen.

**Aufwand:** klein.

**Risiko:** mittel, weil DB-RPC und Migration betroffen sind.

**Nutzen:** Beseitigt einen echten Datenintegritäts-Race.

**Status:** Vorbereiten, nicht in dieser Zweitprüfung live geändert.

### P2: Shared-Plan UPDATE-Semantik härten

**Problem:** Direkte Table-UPDATEs sind semantisch breiter als die vorgesehenen RPCs.

**Lösung:** Änderbare Felder enger beschränken oder Mutation vollständig über RPCs führen.

**Aufwand:** mittel.

**Risiko:** mittel.

**Nutzen:** geringere Manipulationsfläche und klarere Datenintegrität.

### P2: Realtime-Subscriptions filtern

**Problem:** mehrere globale Table-Subscriptions lösen Full Reloads aus.

**Lösung:** Benutzer-/Plan-/Connection-bezogene Filter dort verwenden, wo Supabase Realtime dies für die jeweilige Query zulässt.

**Aufwand:** mittel.

**Risiko:** mittel, weil Filter mit RLS und aktueller Channel-Logik zusammenspielen.

**Nutzen:** weniger unnötige Reloads und bessere Skalierung.

### P2: Asset-Optimierung

**Problem:** rund 67 MB Assets, davon 55,5 MB Hintergründe.

**Lösung:** gezielte Bildkompression und passende Zielauflösungen.

**Aufwand:** mittel.

**Risiko:** niedrig, wenn visuell geprüft.

**Nutzen:** App-Größe, Start-/Downloadkosten und Speicherverbrauch.

### P2: Verhaltenstests ergänzen

**Problem:** viele Regressionstests sind Source-basiert.

**Lösung:** kritische Flows als echte Unit-/Widget-/Integrationstests abbilden.

**Aufwand:** mittel bis hoch.

**Risiko:** niedrig.

**Nutzen:** bessere Schutzwirkung gegen echte Regressionen.

### P1/P2: Migration Drift bereinigen

**Problem:** lokale und Live-Historie unterscheiden sich stark.

**Lösung:** Baseline-/Reconcile-Verfahren statt rückwirkender Migration-Umschreibung.

**Aufwand:** mittel.

**Risiko:** hoch, wenn unkontrolliert.

**Nutzen:** reproduzierbare Deployments.

## 25. Änderungen, die bewusst NICHT vorgenommen wurden

- keine komplette Clean-Architecture-Migration
- kein Wechsel des State-Management-Frameworks
- keine aggressive Indexbereinigung
- keine pauschale Entfernung von SECURITY DEFINER
- keine Umstellung von Anonymous Auth
- keine pauschale Realtime-Neuarchitektur
- keine Änderung der Geschäftslogik ohne reproduzierbaren Befund
- keine Migration gelöscht oder rückwirkend umnummeriert
- keine Edge Function ohne konkreten Nachweis umgestellt

## 26. Behoben

- AsyncController-Test um echten In-Flight-Dispose-Fall erweitert
- AsyncController-Test um stale-error-vs-success erweitert
- Beschreibung des zentralen Stale-Response-Tests präzisiert

## 27. Offen

1. **P1:** Race Condition in `join_connection()`
2. **P1/P2:** Migration-/Schema-Drift zwischen ZIP und Live-Projekt
3. **P2:** zu breite Realtime-Subscriptions / Full Reloads
4. **P2:** Shared-Plan UPDATE-Semantik härten
5. **P2:** Asset-Größe reduzieren
6. **P2:** mehr echte Verhaltenstests / Integrationstests
7. **P2:** Rate-Limit-/Missbrauchsstrategie für `restaurant-discovery`

## 28. Nicht erforderlich

- kein Architektur-Neustart
- keine pauschale Entfernung der vorhandenen SECURITY DEFINER-RPCs
- keine Entfernung der beiden neuen FK-Indizes nur wegen `unused_index`
- kein Wechsel weg von Anonymous Auth allein aufgrund des Advisors
- keine vollständige Realtime-Neuentwicklung
- keine blind ausgeführte Parallelisierung von Futures
- keine Änderung an produktiver Geschäftslogik ohne konkreten reproduzierbaren Fehler

## 29. Roadmap

### Sofort vorbereiten

1. `join_connection()` mit Row-Lock härten.
2. Migration Drift als eigenes technisches Release-Thema dokumentieren.
3. Async-Regressionstest nach Wiederherstellung einer Flutter-Umgebung ausführen.

### Danach

4. Realtime-Subscriptions schrittweise filtern.
5. Shared-Plan UPDATE-Oberfläche enger machen.
6. RLS- und RPC-Verhalten mit zwei echten Anonymous Sessions testen.
7. Kritische Integrationstests für Connect, Today, Shopping und Sharing hinzufügen.

### Später

8. Asset-Kompression.
9. Große Feature-Dateien schrittweise zerlegen.
10. Source-basierte Regressionstests dort durch Verhaltenstests ersetzen, wo die Geschäftslogik besonders kritisch ist.

## 30. Schlussfolgerung

Die vorherige technische Optimierung war nicht nur kosmetisch: insbesondere der Generation Guard im `AsyncController` und die beiden FK-Indizes sind tatsächlich im Code bzw. in der Live-Datenbank vorhanden.

Die Zweitprüfung zeigt aber, dass einige Aussagen zu stark formuliert waren. Der Regressionstest war zunächst schwächer als behauptet, die Migration für die neuen Indizes ist nicht Bestandteil der Live-Historie, und ein echter Datenintegritäts-Race in `join_connection()` wurde übersehen.

Der wichtigste nächste technische Schritt ist deshalb nicht ein Architekturumbau, sondern die Absicherung der Connection-Mitgliedergrenze und anschließend die Bereinigung des Migration-/Schema-Drifts.

Die aktuelle Anwendung wirkt technisch grundsätzlich tragfähig, aber noch nicht so reproduzierbar und konfliktfest, dass man die Optimierungsphase einfach als abgeschlossen betrachten sollte.
