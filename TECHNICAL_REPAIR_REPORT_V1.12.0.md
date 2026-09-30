# Technical Repair Report
## Schmackofatz v1.12.0 – Recipe Sharing

**Stand:** 22.09.2026
**Projekt:** Schmackofatz_v1.12.0_recipe_sharing
**Backend:** Supabase / PostgreSQL 17

## 1. Executive Summary

Die technische Reparatur wurde konservativ durchgeführt. Es wurden nur Änderungen vorgenommen, die in der verfügbaren Umgebung sicher nachvollziehbar und ohne unnötige Produkt-/Architekturänderung vertretbar waren.

### Tatsächlich durchgeführt

1. SECURITY-DEFINER-Hardening für alle aktuell live vorhandenen SECURITY-DEFINER-Funktionen, die `pg_temp` im `search_path` enthielten.
2. Der lokale Security-Smoke-Test wurde verschärft: SECURITY-DEFINER-Funktionen müssen nun exakt `search_path=public` verwenden.
3. Die bestehende Migration Drift wurde nicht künstlich als „behoben“ deklariert. Sie wurde detailliert dokumentiert und mit einem reproduzierbaren Final-Schema-Smoke-Test abgesichert.
4. Live-Supabase wurde nach der Migration erneut geprüft.
5. RLS-Isolation wurde mit echten vorhandenen Auth-User-IDs unter der `authenticated`-Rolle statisch/live gegen die Datenbank geprüft.
6. Die zuvor vorhandene `join_connection()`-Concurrency-Härtung bleibt erhalten und wurde im aktuellen Live-Schema bestätigt.

### Nicht durchgeführt

- kein destruktives Schema-Reset
- keine Datenlöschung
- keine Migrationen gelöscht oder umgeschrieben
- keine Änderung des Anonymous-Auth-Modells
- keine pauschale Entfernung von SECURITY-DEFINER
- keine Änderung der RLS-Logik ohne reproduzierten Bypass
- kein Realtime-Refactoring ohne messbares Lastprofil
- kein Flutter-State-Management-Umbau

## 2. Migration Drift

Im Repository befinden sich nach der Reparatur 63 SQL-Migrationen.

Die Live-Datenbank besitzt aktuell 41 registrierte Migrationen. Die Differenz ist historisch und strukturell, nicht nur ein fehlender letzter Commit.

Die lokalen frühen Migrationen enthalten die ehemalige Household-/Weekly-/Meal-Planning-Architektur. Spätere Migrationen entfernen diese Architektur wieder. Die Live-Migrationshistorie beginnt bereits nach diesem historischen Übergang.

Beispiel:

- lokal: `202609090001_initial.sql` mit Household-Modell
- lokal: mehrere weitere Household-/Weekly-Migrationen
- lokal: `202609140002_remove_household_legacy_and_normalize_food_categories.sql`
- live: beginnt bei `remove_household_legacy_and_normalize_food_categories`

Damit ist ein vollständiger Replay aller Repository-Migrationen auf einer frischen Datenbank in dieser Umgebung nicht verifizierbar.

Eine temporäre Supabase-Branch-Datenbank wurde nicht automatisch angelegt, da deren Erstellung eine separate Kostenbestätigung erfordert. Die lokale Umgebung besitzt außerdem weder Supabase CLI noch PostgreSQL Runtime.

### Entscheidung

Historische Migrationen wurden nicht gelöscht oder umgeschrieben. Stattdessen wurde der aktuelle Endzustand als expliziter Contract dokumentiert.

Datei:

`docs/MIGRATION_DRIFT_RECONCILIATION.md`

Der verbleibende Drift ist damit **dokumentiert, aber nicht vollständig behoben**.

## 3. SECURITY-DEFINER-Hardening

### Änderung

Neue Migration:

`supabase/migrations/20260922201831_security_definer_search_path_hardening.sql`

Für 13 SECURITY-DEFINER-Funktionen wurde `search_path` von:

`public, pg_temp`

auf:

`public`

reduziert.

Die betroffenen Funktionen verwenden ausschließlich schemaqualifizierte `public.*`-Objekte und benötigen keine temporären Tabellen oder Funktionen. Ein `pg_temp`-Eintrag war deshalb nicht erforderlich.

### Betroffene Funktionen

- `create_connection()`
- `create_decision_request(uuid)`
- `accept_decision_request(uuid)`
- `resolve_decision_request(uuid,text,text,text,integer)`
- `cancel_decision_request(uuid)`
- `update_shared_recipe_plan_servings(uuid,integer)`
- `cancel_shared_recipe_plan(uuid)`
- `replace_shared_recipe_plan(uuid,uuid,integer)`
- `share_recipe_for_today(uuid,integer)`
- `add_favorite_recipe(text,text,jsonb,jsonb)`
- `create_recipe_suggestion(uuid)`
- `save_recipe_with_ingredients(jsonb,jsonb)`
- `respond_to_recipe_suggestion(uuid,boolean)`

### Verifikation

Live-Supabase bestätigt anschließend für alle öffentlichen SECURITY-DEFINER-Funktionen:

`proconfig = {search_path=public}`

Außerdem wurde bestätigt, dass keine öffentliche SECURITY-DEFINER-Funktion für `anon` ausführbar ist.

## 4. RLS-Verifikation

Mit realen bestehenden Auth-User-IDs wurde die Isolation unter PostgreSQL-Rolle `authenticated` geprüft.

Für Benutzer A wurden unter anderem sichtbar:

- 1 eigenes Profil
- 76 eigene Food Preferences
- 0 Recipes
- 0 persönliche Today-Pläne

Für Benutzer B wurden unter anderem sichtbar:

- 1 eigenes Profil
- 85 eigene Food Preferences
- 0 Recipes
- 0 persönliche Today-Pläne

Zusätzlich wurde geprüft, dass Benutzer A fremde Recipes eines anderen Users nicht lesen kann:

`foreign_recipe_rows = 0`

Für eine bestehende Connection wurde außerdem geprüft:

- Connection-Mitglied: 1 sichtbare Connection
- Nichtmitglied: 0 sichtbare Connections

Diese Tests sind **LIVE VERIFIZIERT**, aber keine vollständigen Multi-Client-Security-Tests.

## 5. Security Advisor

Nach dem Hardening verbleibt der Advisor-Hinweis, dass 20 SECURITY-DEFINER-Funktionen für `authenticated` ausführbar sind.

Das ist in diesem Projekt teilweise bewusst, da diese Funktionen als RPC/API-Endpunkte für geschützte Geschäftsoperationen verwendet werden.

Der Hinweis wurde deshalb nicht durch pauschales `REVOKE EXECUTE` beseitigt, weil dies bestehende Produktfunktionen beschädigen könnte.

Das verbleibende Thema ist **Defense-in-Depth / API-Flächenminimierung**, kein reproduzierter Privilege-Escalation-Befund.

## 6. `is_connection_member(connection_id, user_id)`

Die Funktion bleibt bewusst unverändert.

Grund:

- sie wird von mehreren bestehenden Policies/RPCs für serverseitige Prüfungen eines Zielbenutzers verwendet
- ein Umbau auf ausschließlich `auth.uid()` würde mehrere Policies und RPCs gleichzeitig verändern
- ein konkreter Cross-User-Zugriffsbypass wurde nicht reproduziert

Sie bleibt als P2-Defense-in-Depth-Thema dokumentiert.

## 7. Anonymous Auth

Die Live-Datenbank enthält aktuell 15 User, davon 15 Anonymous Auth User.

Supabase Advisor meldet deshalb weiterhin Anonymous-Access-Warnungen für Tabellen mit `authenticated`-Policies.

Das wurde nicht verändert, da die aktuelle Anwendung auf diesem Auth-Modell basiert und eine Umstellung ohne Produktanforderung unnötig riskant wäre.

Die Leaked-Password-Protection-Warnung bleibt ebenfalls offen, da derzeit keine normale Passwortauthentifizierung als Grundlage des geprüften Modells nachgewiesen wurde.

## 8. Realtime / Performance

Es wurde bewusst keine pauschale Realtime-Optimierung durchgeführt.

Der aktuelle Aufbau verwendet teilweise:

`Realtime Event → Reload → DB Queries → UI Update`

Die Generation Guards gegen veraltete Async-Antworten bleiben erhalten.

Eine echte Performance-Messung wurde nicht durchgeführt, da keine realistische Lastumgebung vorhanden ist. Die 17 vom Advisor gemeldeten unbenutzten Indizes wurden deshalb nicht gelöscht.

## 9. Testarchitektur

Source-basierte Regressionstests wurden identifiziert. Beispiele befinden sich unter anderem in:

- `test/regression/personal_first_architecture_test.dart`
- `test/regression/today_plan_test.dart`
- `test/regression/ux_stability_test.dart`
- `test/regression/today_home_ux_test.dart`
- `test/regression/today_center_v18_test.dart`

Diese Tests bleiben zunächst bestehen.

Grund: Flutter/Dart Runtime ist in der verfügbaren Umgebung nicht installiert. Eine Umstellung auf Widget-/Integrationstests ohne anschließende echte Ausführung würde lediglich neue, ungetestete Testartefakte produzieren.

Das Thema bleibt daher offen und als P2-Testarchitektur-Schuld dokumentiert.

## 10. Flutter Runtime

Nicht ausführbar:

- `flutter analyze`
- `flutter test`
- `flutter build`
- Widget Runtime Tests
- Integration Tests
- echte Multi-Client Flutter Tests

Die benötigten Executables `flutter`, `dart` und `supabase` sind in der aktuellen Umgebung nicht vorhanden.

Ein einfacher statischer Klammer-/Delimiter-Smoke-Test der zuletzt bearbeiteten Dart-Dateien wurde durchgeführt und war für alle geprüften Dateien ausgeglichen. Dies ersetzt keinen Dart-Parser und keinen Flutter Build.

## 11. Migration Smoke Test

Der Inhalt von `supabase/tests/smoke.sql` wurde um eine strengere SECURITY-DEFINER-Prüfung ergänzt.

Der relevante Live-Smoke-Test wurde anschließend direkt gegen Supabase ausgeführt und erfolgreich beendet.

Geprüft wurden unter anderem:

- retired AI generation objects entfernt
- SECURITY-DEFINER-Funktionen mit `search_path=public`
- keine SECURITY-DEFINER-Funktion für `anon` ausführbar
- Personal Today Tabellen vorhanden
- Personal Today RPCs vorhanden
- Personal Today RPCs SECURITY INVOKER
- zusätzliche FK-Indizes vorhanden

## 12. Concurrency

Die vorherige Migration

`20260922193047_harden_join_connection_concurrency.sql`

ist weiterhin Teil des Repositorys und live registriert.

Die aktuelle `join_connection()`-Funktion verwendet `FOR UPDATE` auf dem Connection-Datensatz und serialisiert damit konkurrierende Join-Versuche derselben Connection.

Ein echter Zwei-Client-Concurrency-Test konnte nicht ausgeführt werden.

Status:

**STATISCH + LIVE VERIFIZIERT, Runtime-Concurrency OFFEN**

## 13. Befundmatrix

| Befund | Änderung | Status |
|---|---|---|
| SEC-01 | SECURITY-DEFINER search_path gehärtet | teilweise behoben, API-Fläche offen |
| SEC-02 | Anonymous Auth bewusst unverändert | offen / kontextabhängig |
| DB-01 | Migration Drift dokumentiert und Contract-Smoke erweitert | offen, Fresh-Replay nicht verifiziert |
| DB-02 | keine Policy-Konsolidierung ohne Verhaltens-/Performance-Nachweis | offen |
| ASYNC-01 | Generation Guards bereits vorhanden | behoben / statisch verifiziert |
| ASYNC-02 | Realtime Full Reloads nicht ohne Lastprofil geändert | offen |
| CONN-01 | `join_connection()` Locking bereits vorhanden | statisch + live verifiziert |
| TEST-01 | Source-basierte Tests identifiziert | offen |
| TEST-02 | Multi-Client Tests wegen fehlender Runtime offen | offen |
| PERF-01 | unbenutzte Indizes nicht entfernt | bewusst offen |
| ARCH-01 | große StatefulWidgets nicht ohne Runtime-Test refaktoriert | offen |

## 14. Verifikationsmatrix

| Prüfung | Status |
|---|---|
| Live-Schema | LIVE VERIFIZIERT |
| Migration History | LIVE VERIFIZIERT |
| RLS Policies | LIVE VERIFIZIERT |
| Foreign Keys | LIVE VERIFIZIERT |
| Indizes | LIVE VERIFIZIERT |
| SECURITY-DEFINER search_path | LIVE VERIFIZIERT |
| SECURITY-DEFINER `anon` Execute | LIVE VERIFIZIERT |
| Supabase Security Advisor | LIVE VERIFIZIERT |
| Supabase Performance Advisor | LIVE VERIFIZIERT |
| Realtime Tabellen | LIVE VERIFIZIERT |
| Edge Functions | LIVE VERIFIZIERT |
| Async-Architektur | STATISCH VERIFIZIERT |
| Flutter Lifecycle | STATISCH VERIFIZIERT |
| Flutter Analyze | NICHT AUSFÜHRBAR |
| Flutter Test | NICHT AUSFÜHRBAR |
| Flutter Build | NICHT AUSFÜHRBAR |
| Flutter Runtime | NICHT AUSFÜHRBAR |
| Zwei-Client-Concurrency | NICHT AUSFÜHRBAR |
| echte Realtime Multi-Client Tests | NICHT AUSFÜHRBAR |
| Produktionslast | NICHT AUSFÜHRBAR |
| Fresh-DB kompletter Migration Replay | NICHT AUSFÜHRBAR |

## 15. Offene Risiken

### P1/P2 – Migration Drift

Die größte verbleibende Infrastruktur-Schuld. Eine vollständige Reproduzierbarkeit aus dem aktuellen Repository wurde nicht bewiesen.

**Nächster Schritt:** Disposable PostgreSQL/Supabase-Umgebung bereitstellen, vollständigen Migration Replay ausführen und Katalog vergleichen.

### P2 – SECURITY-DEFINER API-Fläche

20 SECURITY-DEFINER-Funktionen sind für `authenticated` aufrufbar. Das ist teilweise beabsichtigt, sollte aber langfristig minimiert werden.

**Nächster Schritt:** Funktion für Funktion prüfen, ob Invoker-Security oder nicht öffentlich exponierte Funktionen möglich sind.

### P2 – `is_connection_member(connection_id,user_id)`

Unnötig breite Informations-/Autorisierungsoberfläche möglich, aber kein reproduzierter Bypass.

**Nächster Schritt:** interne Helper-Funktion oder restriktivere API-Struktur prüfen.

### P2 – Multi-Client-Tests

Nicht ausführbar.

**Nächster Schritt:** isolierte Testumgebung mit zwei echten Sessions.

### P2 – Testarchitektur

Source-basierte Regressionstests bleiben wartungsanfällig.

**Nächster Schritt:** nach Bereitstellung einer Flutter Runtime schrittweise auf Verhaltenstests umstellen.

### P2 – Realtime Full Reloads

Plausibles Skalierungsrisiko, aktuell nicht messbar.

**Nächster Schritt:** mit realistischen Daten und Event-Raten messen.

## 16. Rollback

Die neue Datenbankänderung ist nicht destruktiv. Ein Rollback der Search-Path-Härtung kann über die vorherige Konfiguration `search_path=public, pg_temp` erfolgen, sofern dafür wider Erwarten ein konkreter Bedarf nachgewiesen wird.

Die Flutter-Codebasis wurde in dieser Reparaturrunde nicht funktional umgebaut.

## 17. Abschlussbewertung

### P0

Kein P0-Befund identifiziert.

### P1

Kein reproduzierbarer P1-Sicherheits- oder Datenintegritätsfehler identifiziert. Die Migration Drift bleibt allerdings eine ernsthafte Infrastruktur-Schuld, deren vollständige Reproduzierbarkeit noch nicht verifiziert werden konnte.

### Migration Drift

**Nicht behoben, sondern belastbar dokumentiert und mit einem Final-Schema-Smoke-Test abgesichert.**

### RLS

Die geprüften RLS-Isolationsfälle funktionieren unter echten vorhandenen Auth-IDs. Kein Cross-User-Rezeptzugriff wurde reproduziert.

### SECURITY DEFINER

Search-Path wurde gehärtet. Die bewusst exponierte RPC-Fläche bleibt bestehen und muss langfristig weiter minimiert werden.

### Multi-Client

Nicht verifiziert.

### Testarchitektur

Nicht vollständig verbessert, da die erforderliche Flutter Runtime fehlt. Die problematischen Source-basierten Tests wurden identifiziert.

### Performance

Keine ungemessenen Optimierungen durchgeführt.

### Flutter Refactoring

Bewusst zurückgestellt, um ohne Runtime keine neue Regression einzubauen.

## Finaler technischer Status

**Weitere Verifikation erforderlich.**

Eine vollständige Fehlerfreiheit oder hundertprozentige Sicherheit konnte nicht bestätigt werden, weil die erforderlichen Runtime-, Build-, Multi-Client- oder Lasttests in der verfügbaren Umgebung nicht ausgeführt werden konnten.
