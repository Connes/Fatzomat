# TECHNICAL_AUDIT_FINAL_ITERATIVE_V1.12.0

## 1. Executive Summary

Diese iterative Vollprüfung wurde auf dem tatsächlich vorliegenden Stand von `Schmackofatz_v1.12.0_recipe_sharing_third_review.zip` durchgeführt. Der Prüfansatz war nicht nur dokumentarisch: Code, Tests, lokale Migrationen und das verbundene Supabase-Projekt wurden erneut untersucht. Wo ein reproduzierbarer technischer Befund vorlag, wurde die kleinste sinnvolle Korrektur umgesetzt und anschließend erneut geprüft.

Wichtige Ergebnisse:

- Die bereits gehärtete `join_connection()`-Funktion wurde erneut verifiziert. Der Row-Lock auf der Connection-Zeile serialisiert konkurrierende Joins derselben Connection.
- Der `AsyncController` schützt stale Success und stale Error über einen Generation Counter. Die Dispose-Behandlung wurde zusätzlich gehärtet: Nach `dispose()` werden keine verspäteten Ergebnisse mehr in `_data` oder `_error` veröffentlicht.
- Mehrere Realtime-getriggerte `load()`-Pfade hatten weiterhin kein Generation-/Stale-Response-Schutz. Betroffen waren insbesondere Saved Recipes, Recipe Suggestions, Connection, Shopping List, Notifications, Profile sowie der eingebettete Shopping-Load in Today. Diese Pfade wurden mit minimalen Generation Countern abgesichert.
- Die vorhandenen FK-Indizes `idx_personal_decision_history_plan_id` und `idx_personal_today_plans_recipe_id` existieren weiterhin. Ihre idempotente Audit-Migration ist jetzt Bestandteil der Live-Migrationshistorie.
- RLS ist auf den geprüften Public-Tabellen aktiviert. Die Policies verwenden überwiegend explizite Ownership-/Membership-Prüfungen. Es wurde kein direkter BOLA-/IDOR-Pfad aus dem geprüften Policy-Bestand nachgewiesen.
- Die Live-Supabase-Prüfung zeigt weiterhin 20 öffentlich exponierte `SECURITY DEFINER`-RPCs für `authenticated`. Das ist als Angriffsfläche relevant, aber der aktuelle Befund zeigt bei den geprüften Funktionen keine unmittelbar reproduzierte Autorisierungsumgehung. Die Funktionen besitzen `search_path`-Absicherung; `pg_temp` erscheint bei mehreren Funktionen hinter `public`.
- Anonymous Auth bleibt bewusst im Einsatz. Der Supabase Advisor meldet deshalb erwartungsgemäß Policies für `authenticated`, obwohl anonyme Sessions dieselbe Postgres-Rolle verwenden. Daraus allein wurde keine Sicherheitslücke abgeleitet.
- Die Migration-Historie bleibt die größte strukturelle offene Baustelle: lokal liegen 62 SQL-Migrationen, während Supabase 40 Migrationseinträge meldet. Die beiden aktuellen Audit-Migrationen sind synchronisiert, ältere Divergenzen bestehen weiterhin.
- Flutter und Dart sind in der verfügbaren Umgebung nicht installiert. Deshalb wurden keine Flutter-Testergebnisse erfunden. `flutter analyze`, `flutter test` und Builds bleiben infrastrukturell nicht verifizierbar.

Es wurde bewusst kein großflächiger Architekturumbau vorgenommen.

---

## 2. Tatsächliche Ausgangsbasis

Untersuchtes Projekt: `Schmackofatz_v1.12.0_recipe_sharing_third_review.zip`

Festgestellter Umfang:

- 135 Dart-Dateien insgesamt in `lib/`, `test/` und vorhandenen Projektbereichen
- 64 Dart-Testdateien
- 41 Regressionstests
- 62 lokale SQL-Migrationsdateien
- 2 Edge-Function-Verzeichnisse, davon `restaurant-discovery` als aktive Function und `generate-recipes` als deaktivierte/retired Komponente
- größte Dart-Dateien u. a. `today_page.dart`, `saved_recipes_page.dart`, `add_recipe_page.dart`
- `pubspec.yaml`: Version `1.12.0+211`
- keine `integration_test`-Darttests gefunden

Die tatsächliche Flutter-/Dart-Toolchain war nicht vorhanden:

```text
flutter verfügbar: NEIN
dart verfügbar: NEIN
supabase CLI verfügbar: NEIN
```

Daher keine simulierten Testresultate.

---

## 3. Iterationsprotokoll

### Durchlauf 1: Bestand und offensichtliche Fehlerpfade

Geprüft wurden Projektstruktur, Testbestand, Migrationen, Async-/Realtime-Pfade, SECURITY-DEFINER-Funktionen, RLS und relevante Constraints.

Gefundene relevante technische Punkte:

1. `AsyncController` hatte nach `dispose()` weiterhin die Möglichkeit, interne Daten aus einer verspäteten Response zu aktualisieren.
2. Mehrere Realtime-Listener riefen `load()` ohne Stale-Response-Schutz auf.
3. `join_connection()` war bereits per Row-Lock gehärtet, wurde aber erneut auf Constraints und Transaktionslogik geprüft.
4. Migration-Historie bleibt divergent.
5. Mehrere Source-Based Regressionstests sind vorhanden und sollten langfristig durch Verhaltenstests ergänzt werden.

### Durchlauf 2: Änderungen

Umgesetzt:

- `AsyncController` gegen verspätete State-Veröffentlichung nach Dispose gehärtet.
- Async-Regressionstest um stale-error-after-dispose erweitert.
- Realtime-getriggerte Load-Pfade mit Generation Countern abgesichert.
- vorhandene `join_connection()`-Härtung erneut bestätigt.
- FK-Index-Migration erneut verifiziert.

### Durchlauf 3: Kontrollprüfung

Erneut geprüft:

- Änderungen selbst
- abhängige State-Pfade
- Realtime Listener
- RLS
- SECURITY DEFINER
- Constraints
- Migrationen
- Indexdefinitionen

Keine weitere unmittelbar reproduzierbare technische Korrektur wurde aus der verfügbaren Umgebung sicher abgeleitet.

---

## 4. Async / Race Conditions

### `AsyncController`

Aktuell:

- Generation Counter für parallele Loads
- stale Success wird verworfen
- stale Error wird verworfen
- stale Loading-Abschluss wird verworfen
- `load()` nach Dispose startet keine neue Operation
- verspätete Responses nach Dispose verändern `_data` und `_error` nicht mehr
- keine Notifications nach Dispose

Geprüfte Szenarien auf Code-/Testdesign-Ebene:

- A → B, B zuerst fertig
- B erfolgreich, A fehlerhaft
- Dispose während In-Flight Request
- drei parallele Requests
- stale Failure nach neuerem Success

### Realtime-getriggerte Loads

Folgende Pfade wurden gegen alte Responses abgesichert:

- `SavedRecipesPage`
- `RecipeSuggestionsPage`
- `ConnectionPage`
- `ShoppingListPage`
- `NotificationsPage`
- `ProfilePage`
- `ShoppingPage` innerhalb von Today

Die Lösung verwendet lokale Generation Counter statt eines unnötigen globalen Framework-Refactors.

---

## 5. `join_connection()`

Die aktuelle Live-Funktion enthält:

```sql
select id
into cid
from public.connections
where code = upper(trim(p_code))
for update;
```

Damit wird die Connection-Zeile während der Transaktion gesperrt. Der anschließende Count und Insert für dieselbe Connection können nicht parallel an derselben gesperrten Connection vorbeilaufen.

Zusätzliche relevante Constraints:

- `PRIMARY KEY(connection_id, user_id)`
- `UNIQUE(user_id)`
- `connections.code` unique

Ein eigener Constraint `max 2 members` existiert nicht. Die maximale Mitgliederzahl wird deshalb durch die atomarisierte Funktion garantiert, nicht durch einen separaten Tabellenconstraint.

Eine echte Zwei-Client-Live-Reproduktion konnte mangels zweier interaktiver Flutter-Sessions nicht durchgeführt werden. Die DB-Funktion wurde jedoch live inspiziert und die Migration wurde live angewendet und verifiziert.

Bewertung: **behoben / DB-seitig abgesichert; Live-Concurrency-Test infrastrukturell offen.**

---

## 6. RLS / Anonymous Auth

Alle geprüften Public-Tabellen haben RLS aktiviert.

Die wichtigen Ownership-Pfade verwenden `auth.uid()` und `USING`/`WITH CHECK`-Prüfungen. Beispiele:

- `profiles`: eigener User
- `user_food_preferences`: eigener User
- `personal_today_plans`: eigener User plus Rezeptzugriffsprüfung
- `personal_decision_history`: eigener User
- `recipe_saves`: eigener User
- `shopping_items`: über persönlichen Plan oder Connection-Mitgliedschaft
- `shared_recipe_plans`: Connection-Mitgliedschaft
- `recipe_suggestions`: Sender/Empfänger plus Connection
- `decision_requests`: Connection-Mitgliedschaft
- `app_notifications`: eigener User

Der aktuelle Advisor warnt weiterhin vor Anonymous Auth, weil Anonymous Sessions die `authenticated`-Rolle verwenden. Diese Warnung ist kein Beweis für Datenexfiltration.

Ein direkter Cross-User-RLS-Bypass wurde aus dem geprüften Policy-Bestand nicht nachgewiesen.

---

## 7. SECURITY DEFINER

Die Live-Datenbank enthält 20 `SECURITY DEFINER`-Funktionen, die für `authenticated` ausführbar sind.

Geprüfte Eigenschaften:

- `search_path` gesetzt
- `anon`-Ausführung für die geprüften APIs nicht erlaubt
- `auth.uid()` wird in den relevanten mutierenden Funktionen verwendet
- Parameter werden vielfach gegen Ownership/Connection geprüft
- kritische Updates verwenden zusätzliche Status-/User-Bedingungen

Auffällig, aber nicht als unmittelbare Schwachstelle reproduziert:

`is_connection_member(p_connection_id, p_user_id)` kann mit explizitem User-Parameter als authenticated RPC aufgerufen werden. Damit existiert eine öffentlich erreichbare Membership-Abfrage für bekannte UUIDs. Das ist eine unnötige Informationsoberfläche und sollte bei einer späteren Security-Härtung geprüft werden, wurde aber wegen fehlender reproduzierbarer sicherheitskritischer Auswirkung nicht als P0/P1 geändert.

---

## 8. Datenintegrität und Constraints

Relevante geprüfte Constraints:

- Personal Today: maximal ein aktiver Plan pro User/Tag
- Shared Today: maximal ein aktiver Plan pro Connection/Tag
- Shopping Items: genau eine Planquelle
- Decision Requests: maximal ein pending Request pro Connection über Unique Partial Index
- Connection Members: User nur einmal über `UNIQUE(user_id)`
- Servings: 1–12
- Statuswerte über Check Constraints
- Foreign Keys mit passenden Delete-Regeln

Damit sind mehrere frühere Race-Condition-Klassen bereits auf DB-Ebene abgesichert.

---

## 9. Realtime

Aktive relevante Realtime-Tabellen:

- `app_notifications`
- `connection_members`
- `decision_requests`
- `personal_today_plans`
- `recipe_suggestions`
- `shared_recipe_plans`
- `shopping_items`

Listener werden beim Dispose entfernt.

Der wesentliche neu behobene Fehler war nicht das Realtime-Protokoll selbst, sondern die State-Konsistenz nach Realtime-getriggerten parallelen Loads.

---

## 10. Migrationen

Aktueller Stand:

```text
Repository: 62 Migrationen
Supabase:   40 Migrationseinträge
```

Die beiden aktuellen Audit-Migrationen sind live vorhanden:

- `20260922193047_harden_join_connection_concurrency`
- `20260922193140_audit_add_missing_fk_indexes`

Damit ist die aktuelle Änderungshistorie dieser Prüfung nachvollziehbar.

Die ältere Divergenz bleibt offen. Ein frisches Projekt lässt sich nicht allein anhand der vollständigen lokalen Historie als garantiert identisch zum aktuellen Live-Schema beweisen.

Keine alten Migrationen wurden gelöscht oder umbenannt.

---

## 11. Indizes

Verifiziert:

```text
idx_personal_decision_history_plan_id(plan_id)
idx_personal_today_plans_recipe_id(recipe_id)
```

Sie bleiben bestehen.

Die vorherige Advisor-Meldung `unused index` wurde nicht als ausreichender Löschgrund interpretiert.

Die Indizes sind als FK-/Lookup-Indizes technisch plausibel; ein belastbarer Produktions-Query-Plan-Nachweis war wegen fehlender realer Flutter-/Lastumgebung nicht möglich.

---

## 12. Tests

Vorhanden:

- 64 Dart-Testdateien
- 41 Regressionstests
- AsyncController-Verhaltenstests
- zahlreiche Source-Based Regressionstests

Die Source-Based Tests sind weiterhin eine technische Schwäche. Sie können korrekte Implementierungen durch reine Codeformatänderungen brechen.

Es wurde bewusst kein großflächiger Testumbau vorgenommen, da ohne ausführbare Flutter-Toolchain die sichere Verifikation größerer Teständerungen nicht möglich ist.

### Tatsächlich ausgeführt

Keine Flutter-/Dart-Tests, weil Toolchain fehlt.

Tatsächlich ausgeführt wurden dagegen:

- Projekt-/Dateiinspektion
- lokale Codeanalyse per Shell/Python
- Live-SQL-Abfragen
- Live-Schema-/Constraint-Prüfungen
- Live-RLS-Prüfungen
- Live-Function-/Privilege-Prüfungen
- Live-Realtime-Prüfung
- Live-Migrationsprüfung
- Live-Indexprüfung
- Live-Anwendung der beiden Audit-Migrationen

---

## 13. Edge Functions

`restaurant-discovery` verwendet weiterhin `verify_jwt=false`, führt aber serverseitig eine User-Authentifizierungsprüfung durch.

Das ist funktional nicht dasselbe wie ein ungeschützter Endpoint. Das verbleibende Risiko liegt primär bei Missbrauch/Abuse und fehlendem explizitem Rate-Limiting, nicht bei einem aus der vorliegenden Prüfung nachgewiesenen Auth-Bypass.

`generate-recipes` ist deaktiviert und liefert keinen aktiven Generierungsdienst.

---

## 14. Performance / Assets

Der Projektumfang enthält weiterhin große Assets und mehrere große Feature-Dateien.

Das wurde nicht pauschal refaktoriert oder komprimiert, weil kein ausreichender Nachweis eines aktuellen Produktionsengpasses vorlag.

Realtime-Full-Reloads bleiben ein möglicher Performancepunkt. Die neue Generation-Härtung verbessert die Konsistenz, reduziert aber nicht automatisch die Anzahl der Reloads.

---

## 15. Source-Based Regression Tests

Es existieren weiterhin viele Tests, die Dateien einlesen und auf konkrete Strings prüfen.

Das ist kein unmittelbarer Produktionsfehler, aber eine Testarchitektur-Schwäche.

Status: **bewusst offen / P2**.

---

## 16. Finale Fehlerliste

| Bereich | Problem | Reproduziert | Ursache | Änderung | Test danach | Ergebnis | Status |
|---|---|---:|---|---|---|---|---|
| AsyncController | stale State nach Dispose | Code-/Testfall | fehlender Dispose-Schutz beim Ergebnis | Generation + Dispose Guard | deterministischer Unit-Test vorhanden | logisch behoben, Flutter-Lauf offen | BEHOBEN |
| AsyncController | stale Success/Error | ja im Testdesign | parallele Loads | Generation Counter | mehrere Completer-Szenarien | korrekt geschützt | BEHOBEN |
| Realtime Loads | alte Response konnte neueren Load überschreiben | Codepfad | kein Load-Generation-Schutz | Generation Counter in betroffenen Pages | statische Nachprüfung | geschützt | BEHOBEN |
| `join_connection()` | Count/Insert Race | technisch reproduzierbares Interleaving | fehlender Row-Lock | `FOR UPDATE` | Live-Funktionsprüfung | atomarisierter Ablauf | BEHOBEN |
| Migrationen | Repository/Live-Historie divergent | ja | historische Änderungen außerhalb konsistenter Migrationen | aktuelle Audit-Migrationen nachgetragen | Live-Migrationsprüfung | ältere Drift offen | BEWUSST OFFEN |
| FK-Indizes | Historisierung fehlte | ja | Index bereits vorhanden, Migration fehlte | idempotente Migration | Live-Indexprüfung | nachvollziehbar | BEHOBEN |
| RLS | kein direkter Cross-User-Bypass nachgewiesen | nein | - | keine Änderung | Policy-Matrix | kein akuter Fehler | KEIN FEHLER |
| Anonymous Auth | Advisor-Warnungen | ja | Anonymous Sessions = authenticated role | keine Änderung | RLS-/Role-Prüfung | kein Beweis einer Lücke | KEIN FEHLER |
| SECURITY DEFINER | große exponierte RPC-Fläche | ja | bewusst verwendete RPC-Architektur | keine pauschale Entfernung | Function-/Privilege-Prüfung | keine reproduzierte Bypass-Lücke | BEWUSST OFFEN |
| Realtime | Full Reloads | ja als Architekturpfad | Listener laden gesamte Daten neu | keine globale Optimierung | Listener-Analyse | funktional, Performancepotenzial | BEWUSST OFFEN |
| Assets | große Dateien | ja | vorhandene Medien | keine pauschale Kompression | Dateianalyse | kein belegter akuter Fehler | BEWUSST OFFEN |
| Edge Functions | `verify_jwt=false` bei restaurant-discovery | ja | serverseitige Auth innerhalb Function | keine Änderung | Code-/Auth-Pfadprüfung | kein nachgewiesener Auth-Bypass | BEWUSST OFFEN |

---

## 17. Behoben

- `join_connection()` Race Condition DB-seitig abgesichert.
- AsyncController gegen stale State nach Dispose gehärtet.
- Async Regression Test erweitert.
- Mehrere Realtime-getriggerte Load-Races abgesichert.
- FK-Index-Migrationen nachvollziehbarer gemacht.

## 18. Offen

### Migration-Historie

Grund: ältere Divergenz zwischen Repository und Live-Historie.

Risiko: Reproduzierbarkeit eines frischen Supabase-Projekts ist nicht vollständig bewiesen.

Nächster Schritt: kontrollierter Schema-/Migration-Abgleich mit Snapshot bzw. `db pull/diff`, bevor historische Migrationen verändert werden.

### Source-Based Tests

Grund: großer Bestand bestehender Tests.

Risiko: Tests können bei Implementierungsrefactorings unnötig brechen.

Nächster Schritt: schrittweise durch Verhaltenstests ersetzen.

### SECURITY-DEFINER API-Fläche

Grund: 20 authenticated-callable SECURITY-DEFINER-Funktionen.

Risiko: größere privilegierte Angriffsfläche; aktuell keine reproduzierte Bypass-Lücke.

Nächster Schritt: öffentliche RPCs einzeln auf minimal notwendige EXECUTE-Rechte und gegebenenfalls private Schema-Auslagerung prüfen.

### Realtime Full Reloads

Grund: bestehende Listener laden Daten erneut.

Risiko: unnötige Requests und mögliche Last bei wachsendem Datenbestand.

Nächster Schritt: eventbasierte inkrementelle State-Updates nur nach Messung.

## 19. Nicht erforderlich

- großflächiger Architektur-Refactor
- pauschale Entfernung ungenutzter Indizes
- pauschale Entfernung von SECURITY DEFINER
- pauschale Abschaffung von Anonymous Auth
- pauschale Asset-Kompression
- komplette Realtime-Neuarchitektur

Für diese Punkte wurde kein ausreichender aktueller technischer Nutzen nachgewiesen.

---

## 20. Schlussbewertung

Der aktuelle Projektstand ist technisch deutlich robuster als der Ausgangsstand der früheren Audits. Die iterative Prüfung hat zusätzlich echte Stale-Load-Risiken in mehreren Realtime-Pfaden gefunden und behoben.

Trotzdem kann der Zustand **nicht als „absolut fehlerfrei bewiesen“** bezeichnet werden, weil die Flutter-/Dart-Ausführungsumgebung fehlt und damit ein echter vollständiger Testlauf sowie echte Zwei-Client-Concurrency-Tests nicht möglich waren.

Der belastbare Schluss lautet daher:

**Keine weiteren reproduzierbaren technischen Fehler wurden in der verfügbaren statischen und Live-Supabase-Prüfumgebung identifiziert. Die verbleibenden Punkte sind entweder nicht ausführbar verifizierbar, strukturelle technische Schulden oder bewusst offene Optimierungsthemen.**

Dieser Bericht unterscheidet ausdrücklich zwischen nachgewiesenen Befunden und technischen Einschätzungen.
