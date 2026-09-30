# Schmackofatz V1.12.0 – Technischer Gesamt-Audit

Stand: 22.09.2026
Grundlage: `Schmackofatz_v1.12.0_recipe_sharing_design_redesign.zip`

## 1. Kurzfazit

Die App besitzt bereits eine brauchbare technische Basis: Feature-/Data-Trennung ist vorhanden, Supabase-Zugriffe liegen überwiegend in Repositories, RLS ist auf den relevanten `public`-Tabellen aktiviert, Realtime wird für die Collaboration-Bereiche eingesetzt und es existiert eine CI-Pipeline mit Lockfile-Erzwingung, Analyse, Tests und Android-Build.

Die größten technischen Risiken liegen aktuell nicht in einer fehlenden Komplettarchitektur, sondern in gewachsener Kopplung innerhalb einzelner großer Screens, vielen direkten Supabase-/Realtime-Zugriffen aus Feature-Seiten, zahlreichen `setState`-basierten Zuständen, begrenzter Offline-Abdeckung, String-basierten Statuswerten und einer historisch stark gewachsenen Supabase-Migrationskette.

## 2. Festgestellte Architektur

Aktueller grober Datenfluss:

`Flutter UI → Feature-Controller/State → Repository/Service → Supabase`

Dieser Aufbau ist grundsätzlich vorhanden, aber nicht überall konsequent. Mehrere Screens greifen direkt auf `Supabase.instance.client` zu, insbesondere für Realtime-Channels. Das erschwert Tests und verteilt Infrastrukturverantwortung über die UI-Schicht.

### Größte Dateien

- `today_page.dart`: 1113 Zeilen
- `saved_recipes_page.dart`: 841 Zeilen
- `add_recipe_page.dart`: 750 Zeilen
- `food_mode_page.dart`: 576 Zeilen
- `additional_ingredients_page.dart`: 471 Zeilen
- `food_onboarding_page.dart`: 416 Zeilen
- `recipe_detail_page.dart`: 393 Zeilen
- `app_design.dart`: 374 Zeilen

Das ist ein deutlicher Hinweis auf gewachsene Feature-Komplexität, aber noch kein Beweis dafür, dass jede Datei zwingend aufgeteilt werden muss.

## 3. State Management

Es wird überwiegend lokaler Flutter-State mit `setState()` verwendet. Zusätzlich existiert ein kleines framework-neutrales `AsyncController`-Abstraktionsmodell, das aktuell insbesondere vom `TodayController` verwendet wird.

Es wurden rund 146 `setState()`-Vorkommen im `lib/`-Bereich gefunden.

### Umgesetzte Verbesserung

`AsyncController` wurde gegen konkurrierende Loads gehärtet. Ein langsamer älterer Request kann jetzt keinen neueren Ladezustand mehr überschreiben. Dafür wurde eine Generation/Request-Sequenz eingeführt und ein Regressionstest ergänzt.

## 4. Supabase

Projekt:

- Ref: `oidxezjdwqktpxuypbfb`
- Region: `eu-central-1`
- PostgreSQL: 17.6.1
- Status: ACTIVE_HEALTHY

Die relevante Datenstruktur für Personal- und Collaboration-Flows ist vorhanden:

- `personal_today_plans`
- `shopping_items`
- `shared_recipe_plans`
- `connections`
- `connection_members`
- `recipes`
- `recipe_saves`
- `recipe_suggestions`
- `decision_requests`
- `app_notifications`

RLS ist auf den geprüften `public`-Tabellen aktiviert.

## 5. RLS / Security

Die RLS-Struktur ist grundsätzlich bewusst aufgebaut und verwendet überwiegend `auth.uid()` sowie Membership-Prüfungen.

Wichtig: Das Projekt verwendet absichtlich Supabase Anonymous Auth. Aktuell sind 15 von 15 Auth-Usern anonym. Deshalb erscheinen Supabase-Advisor-Warnungen zu Policies auf der Rolle `authenticated` als „Anonymous Access Policies“. Das bedeutet in diesem Projekt nicht automatisch eine ungeschützte Datenbank: Supabase ordnet anonyme Auth-User der Rolle `authenticated` zu. Die Policies müssen deshalb als Anonymous-User-Zugriffsmodell bewertet werden, nicht allein anhand des Advisor-Namens.

Die aktuelle Sicherheitsarchitektur sollte dennoch regelmäßig mit echten anonymen und getrennten Testidentitäten geprüft werden.

Supabase Security Advisor meldet außerdem deaktivierten Schutz gegen kompromittierte Passwörter. Da der aktuelle Client ausschließlich Anonymous Auth startet und keinen Passwort-Login anbietet, ist dieser Befund für den aktuellen Auth-Flow nicht unmittelbar relevant. Sollte später Passwort-Auth hinzukommen, muss der Schutz aktiviert werden.

## 6. SECURITY DEFINER

Es existieren mehrere `SECURITY DEFINER`-Funktionen. Die aktuelle Datenbank setzt bei den geprüften Funktionen `search_path` explizit und der vorhandene Smoke-Test prüft, dass öffentliche `SECURITY DEFINER`-Funktionen nicht für `anon` ausführbar sind.

Diese Funktionen sollten trotzdem langfristig einzeln dokumentiert werden: Zweck, notwendiger Privileg-Bypass und Autorisierungsprüfung.

Keine pauschale Migration von `SECURITY DEFINER` auf `SECURITY INVOKER` durchführen, weil mehrere Funktionen bewusst für RLS-übergreifende Operationen eingesetzt werden.

## 7. Performance Advisor

Vor der Optimierung meldete der Performance Advisor zwei nicht indexierte Foreign Keys:

- `personal_decision_history.plan_id`
- `personal_today_plans.recipe_id`

### Umgesetzt

Beide Indizes wurden in der produktiven Supabase-Datenbank angelegt und unmittelbar per SQL verifiziert.

Zusätzlich wurde eine reproduzierbare Migration ergänzt:

`supabase/migrations/20260922210000_audit_add_missing_fk_indexes.sql`

Der Smoke-Test prüft diese beiden Indizes jetzt ebenfalls.

Der Performance Advisor meldet weiterhin 15+ unbenutzte Indizes. Wegen der derzeit kleinen Datenmengen und des jungen Projekts sollten diese nicht vorschnell gelöscht werden. Nutzung sollte nach realer Last erneut bewertet werden.

## 8. Multiple permissive RLS policies

Der Performance Advisor meldet sechs Fälle mit mehreren permissiven Policies für dieselbe Rolle und Operation, unter anderem bei:

- `recipes`
- `recipe_ingredients`
- `recipe_suggestions`

Das ist primär ein Performance-/Komplexitätsthema. Die Policies bilden unterschiedliche fachliche Zugriffswege ab. Eine Konsolidierung ist möglich, sollte aber erst nach Policy-Tests erfolgen, weil eine scheinbar einfache Zusammenführung leicht eine Autorisierungsregel verändert.

Empfehlung: P2, nicht blind automatisieren.

## 9. Realtime

Realtime ist für folgende Tabellen aktiviert:

- `app_notifications`
- `connection_members`
- `decision_requests`
- `personal_today_plans`
- `recipe_saves`
- `recipe_suggestions`
- `shared_recipe_plans`
- `shopping_items`

Die Flutter-Seiten erzeugen mehrere individuelle Channels. Die Channels werden grundsätzlich wieder entfernt, was positiv ist.

Verbesserungspotenzial besteht bei der Wiederverwendung und Koordination der Realtime-Infrastruktur. Mehrere Callbacks lösen aktuell komplette `load()`-Vorgänge aus. Bei mehreren Events hintereinander kann dadurch unnötiger Reload entstehen.

Empfehlung: P2, zunächst messen und anschließend einen kleinen zentralen Realtime-/Reload-Koordinator einführen.

## 10. Offline-Verhalten

`OfflineCache` verwendet `SharedPreferencesAsync` und cached aktuell insbesondere Foods und Today-Daten. Das ist bewusst als Last-known-data-Cache dokumentiert und nicht als Autorisierungsquelle.

Offline ist damit teilweise unterstützt, aber nicht vollständig.

Nicht vollständig offline verfügbar sind insbesondere:

- Shopping List als lokaler vollständiger Datensatz
- Recipes
- Saved Recipes
- Collaboration-Zustand
- Notifications

Empfehlung: nicht sofort Offline-First bauen. Zunächst definieren, welche Funktionen tatsächlich offline funktionieren sollen. P2.

## 11. Fehlerbehandlung

Es existiert eine zentrale Fehlernormalisierung (`AppException` / `async_error`) und mehrere UI-Fehlerzustände.

Gleichzeitig existieren rund 88 `catch`-Blöcke und 17 explizite `catch (_)`, die Fehler teilweise bewusst ignorieren. Einige sind für optionale Cache-/Preview-/Cleanup-Pfade vertretbar. Die Stellen sollten aber einzeln klassifiziert werden.

Empfehlung: P2. Ignorierte Fehler nicht pauschal in UI-Fehler verwandeln, sondern zwischen erwarteten Fallbacks und echten Fehlern unterscheiden.

## 12. Datenmodelle

Es gibt bereits eigene Modelle für zentrale Domänenobjekte. Gleichzeitig werden Statuswerte an mehreren Stellen als Strings geführt, beispielsweise `pending`, `accepted`, `declined`, `cancelled`, `planned` usw.

Das ist funktional, aber fehleranfälliger als stark typisierte Enums/Value Objects.

Empfehlung: P2/P3. Zuerst die zentralsten Statusmodelle migrieren, nicht alle Strings gleichzeitig.

## 13. Navigation

`AppShell` verwendet einen `IndexedStack` mit Heute, Rezepte, Einkauf und Profil. Die Navigation ist überschaubar und der Back-Flow ist explizit über `PopScope` geregelt.

Die Navigation ist derzeit relativ direkt über `Navigator.push(MaterialPageRoute(...))` verteilt. Für die aktuelle App-Größe ist das noch vertretbar. Bei weiterem Wachstum sollte Routing zentraler werden.

Empfehlung: P3, solange keine Deep-Link-/Routing-Komplexität hinzukommt.

## 14. Edge Functions

Aktiv sind:

- `generate-recipes`
- `restaurant-discovery`

`generate-recipes` ist serverseitig deaktiviert und liefert bewusst HTTP 410.

`restaurant-discovery` ist aktuell mit `verify_jwt = false` deployed, führt aber im Handler selbst eine User-Authentifizierung mit `createSupabaseContext(..., { auth: 'user' })` durch. Das ist nicht automatisch eine Sicherheitslücke, weil die Authentifizierung serverseitig erfolgt. Die aktuelle Supabase-Dokumentation empfiehlt für neue Funktionen jedoch das explizite Auth-Modell und eine klare Zuordnung zwischen `verify_jwt` und `auth`-Modus.

Empfehlung: P2, langfristig auf das aktuelle `withSupabase({ auth: 'user' })`-Muster migrieren, sofern die vorhandene Funktionalität damit unverändert bleibt.

## 15. Dependencies

Aktuell verwendet das Projekt unter anderem:

- `supabase_flutter 2.17.2`
- `connectivity_plus 7.3.1`
- `shared_preferences 2.5.5`
- `file_picker 13.1.0`

Die geprüften Versionen sind auf dem aktuellen Stand der jeweils gefundenen stabilen Paketversionen bzw. bei `supabase_flutter` aktuell stabil. `file_picker 13.1.0` wurde wenige Tage vor dem Audit veröffentlicht.

Es besteht daher kein akuter Grund für ein blindes Dependency-Upgrade.

## 16. Tests

Im ZIP befinden sich 63 Dart-Testdateien.

Es gibt keine `integration_test/`-Tests.

Die Regression-Suite enthält viele source-basierte Tests, die Dateien direkt als Text lesen und auf konkrete Codefragmente prüfen. Diese Tests schützen bewusst Architektur-/UX-Verträge, sind aber strukturell fragil: eine technisch gleichwertige Refaktorierung kann einen Test brechen, ohne die Laufzeitfunktionalität zu verändern.

Empfehlung: langfristig mehr echte Unit-/Widget-/Integration-Tests und weniger Source-String-Verträge.

## 17. CI / Release

Die CI-Pipeline ist bereits ordentlich aufgestellt:

- Flutter 3.47.2
- `flutter pub get --enforce-lockfile`
- `flutter analyze`
- `flutter test`
- Android Debug Build
- Android Release-Konfigurationscheck
- Repository-Hygiene

Die lokale Umgebung dieses Audits enthält kein `flutter` und kein `dart`. Deshalb konnten `flutter analyze`, `flutter test` und ein Build hier nicht ausgeführt werden.

Statische Repository-Prüfungen konnten ausgeführt werden und waren erfolgreich:

- `scripts/check_architecture.sh` → erfolgreich
- `scripts/check_repository.sh` → erfolgreich

## 18. Migrations-/Reproduzierbarkeitsrisiko

Das ZIP enthält 60 SQL-Migrationsdateien, während die aktuell verbundene Supabase-Datenbank 38 angewendete Migrationseinträge meldet. Die Versions-/Namenshistorien stimmen nicht 1:1 überein.

Das muss nicht bedeuten, dass das Schema falsch ist, ist aber ein klares Reproduzierbarkeitsrisiko. Die Datenbank wurde offenbar über eine historisch gewachsene oder rekonstruierte Migrationskette weiterentwickelt.

Empfehlung: P1/P2. Vor weiteren größeren Schemaänderungen sollte ein sauberer Schema-/Migrationsabgleich erstellt werden.

## 19. Priorisierte Roadmap

### P0
Keine unmittelbar nachgewiesene P0-Lücke im Audit.

### P1
1. Migrations-/Schema-Historie zwischen Repository und Live-Projekt bereinigen bzw. dokumentieren.
2. Zwei-Personen-RLS-Tests für Anonymous Auth und Collaboration als reproduzierbare Datenbanktests etablieren.
3. SECURITY-DEFINER-Funktionen einzeln dokumentieren und gezielt testen.

### P2
1. Große Feature-Seiten schrittweise in Controller/State/Sections aufteilen.
2. Realtime-Subscriptions zentralisieren bzw. Reloads debouncen.
3. Direkte Supabase-Aufrufe aus UI-Schichten reduzieren.
4. Multiple permissive RLS policies nach Testabdeckung konsolidieren.
5. Fehlerbehandlung der bewusst ignorierten `catch (_) {}`-Stellen klassifizieren.
6. Edge Function `restaurant-discovery` auf das aktuelle Auth-Muster modernisieren.
7. Offline-Strategie fachlich definieren und nur für wichtige Bereiche erweitern.

### P3
1. String-Statuswerte schrittweise durch Enums/Value Objects ersetzen.
2. Routing zentralisieren, falls die App weiter wächst.
3. Source-basierte Regressionstests schrittweise durch Verhaltenstests ergänzen.
4. Unbenutzte Indizes erst nach realer Lastmessung bereinigen.

## 20. Bewusst nicht geändert

Nicht durchgeführt wurden:

- kompletter State-Management-Wechsel
- komplette Clean-Architecture-Migration
- blindes Dependency-Upgrade
- Entfernung von SECURITY DEFINER
- aggressive Indexbereinigung
- Abschalten von Anonymous Auth
- Umbau sämtlicher Realtime-Channels
- vollständiger Offline-First-Umbau

Diese Änderungen hätten ein deutlich höheres Risiko bei vergleichsweise geringer Sicherheit über den tatsächlichen Nutzen.

## 21. Tatsächlich umgesetzte technische Änderungen

1. `AsyncController` gegen Race Conditions bei parallelen Loads gehärtet.
2. Regressionstest für „stale response darf neueren State nicht überschreiben“ ergänzt.
3. Fehlende Indizes für zwei Foreign Keys in Supabase ergänzt.
4. Index-Verifikation in `supabase/tests/smoke.sql` ergänzt.
5. Audit-Bericht erstellt.

## 22. Verifikation

Supabase:

- Indexe erfolgreich angelegt.
- Indexe anschließend per SQL verifiziert.
- Performance Advisor erneut ausgeführt.
- Die beiden FK-Befunde sind damit behoben; die neu angelegten Indizes erscheinen naturgemäß zunächst als „unused“, weil sie noch keine reale Last gesehen haben.

Lokaler Code:

- Repository-Hygiene erfolgreich.
- Architektur-/Release-Härtung erfolgreich.
- Flutter Analyze/Test/Build nicht ausführbar, da Flutter/Dart in dieser Umgebung fehlen.
