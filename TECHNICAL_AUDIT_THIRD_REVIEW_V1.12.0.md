# TECHNICAL_AUDIT_THIRD_REVIEW_V1.12.0

## 1. Executive Summary

Diese dritte Prüfung wurde als unabhängige Gegenprüfung des zuletzt gelieferten zweiten-Review-Stands durchgeführt. Grundlage waren der tatsächlich entpackte Projektstand, die enthaltenen Auditberichte und Migrationen sowie eine erneute Prüfung des verbundenen Supabase-Projekts `oidxezjdwqktpxuypbfb`.

Die dritte Prüfung bestätigt wesentliche Teile der zweiten Prüfung, korrigiert aber zwei wichtige Punkte:

1. Die `join_connection()`-Race-Condition ist nicht nur ein theoretischer Architekturhinweis. Die aktuelle Implementierung prüfte die Mitgliederzahl ohne Sperre und konnte deshalb bei konkurrierenden Joins die Zwei-Personen-Grenze verletzen. Dieser Befund wurde als P1 behandelt und DB-seitig mit einem Row-Lock auf der Connection behoben.
2. Die beiden FK-Indizes waren physisch bereits vorhanden, aber die dazugehörige Migration fehlte in der angewendeten Supabase-Historie. Diese Drift wurde im Rahmen der dritten Prüfung durch eine idempotente Migration nachgetragen. Die historische Migration-Divergenz des Projekts bleibt trotzdem bestehen.

Die AsyncController-Implementierung bleibt technisch plausibel und die zweite Prüfung hat den Regressionstest sinnvoll erweitert. Der Test wurde in der dritten Prüfung um einen deterministischen Drei-Request-Fall ergänzt. Ein echter Flutter-Testlauf war weiterhin nicht möglich, da in der Umgebung weder `flutter` noch `dart` verfügbar sind.

Die größte verbleibende technische Schuld ist nicht der AsyncController, sondern die historisch auseinanderlaufende Migration-/Schema-Historie. Das Projekt enthält nun 62 lokale SQL-Migrationen, während Supabase 40 Migrationseinträge meldet. Die neu hinzugefügten Audit-Migrationen sind jetzt in der Live-Historie vertreten, der ältere Drift bleibt jedoch bestehen.

Es wurde bewusst kein großflächiger Architekturumbau durchgeführt.

---

## 2. Prüfgrundlage

### Projekt

- 71 Dart-Dateien unter `lib/`
- 64 Dart-Testdateien
- keine `integration_test/`-Tests
- `pubspec.yaml` Version `1.12.0+211`
- kein Git-Repository im gelieferten ZIP
- 62 lokale SQL-Migrationsdateien nach den Änderungen der dritten Prüfung
- Edge Function `restaurant-discovery`
- deaktivierte AI-Generation-Komponente
- rund 67 MB Assets
- rund 56 MB Hintergrundbilder

### Live-Supabase

- Projekt: `oidxezjdwqktpxuypbfb`
- Region: `eu-central-1`
- PostgreSQL 17
- 15 Auth-Benutzer; im vorherigen Audit als vollständig anonym identifiziert
- RLS auf den geprüften Public-Tabellen aktiviert
- Realtime für die relevanten Collaboration-/Personal-Tabellen aktiviert
- 40 Migrationseinträge nach den beiden Änderungen der dritten Prüfung

### Ausführungsumgebung

`flutter` und `dart` sind in der verwendeten Umgebung nicht vorhanden.

Deshalb wurden nicht ausgeführt:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter test --coverage`
- `flutter test integration_test`
- Flutter Builds

Diese Punkte werden nicht als erfolgreich getestet dargestellt.

---

## 3. Audit Chain of Evidence

### AsyncController

Audit 1:

- Generation-/Request-Sequenz wurde eingeführt.
- Ziel war die Vermeidung stale Responses.

Audit 2:

- Implementierung als technisch korrekt bewertet.
- Regressionstest wurde um Dispose und stale Error erweitert.

Audit 3:

- Implementierung erneut im tatsächlichen Code geprüft.
- Zwei parallele Requests sowie Fehler-/Success-Kombination sind korrekt geschützt.
- Drei parallele Requests wurden als zusätzlicher Regressionstest aufgenommen.
- Kein echter Flutter-Lauf möglich.

Endgültige Bewertung:

**korrekt implementiert, Verhaltenstest sinnvoll verbessert, Laufzeitverifikation aus Umgebungsgründen offen.**

### FK-Indizes

Audit 1:

- zwei fehlende FK-Indizes identifiziert und physisch angelegt.
- lokale Migration behauptete Reproduzierbarkeit.

Audit 2:

- beide Indizes live bestätigt.
- fehlende Übereinstimmung zwischen lokaler Migration und Live-Historie festgestellt.

Audit 3:

- beide Indizes erneut live bestätigt.
- idempotente Migration `audit_add_missing_fk_indexes` live nachgetragen.
- historische Migration-Divergenz bleibt bestehen.

Endgültige Bewertung:

**physisch korrekt; Deployment-Historie für diese beiden Audit-Änderungen jetzt nachvollziehbarer; Gesamtmigration weiterhin nicht vollständig reproduzierbar.**

### `join_connection()`

Audit 1:

- nicht als kritischer Race-Condition-Punkt erkannt.

Audit 2:

- Race-Condition identifiziert, aber nicht umgesetzt.

Audit 3:

- aktuelle DB-Funktion und Constraints erneut geprüft.
- `connection_members` besitzt zwar `UNIQUE(user_id)`, aber keinen Constraint, der maximal zwei unterschiedliche Benutzer pro Connection erzwingt.
- Die ursprüngliche Reihenfolge `count -> insert` war damit nicht atomar.
- Funktion wurde per Migration mit `SELECT ... FOR UPDATE` auf der Connection-Zeile gehärtet.

Endgültige Bewertung:

**P1-Befund bestätigt und behoben.**

---

## 4. Validierung des zweiten Audits

| Befund aus Audit 2 | Audit 3 | Bewertung |
|---|---|---|
| AsyncController verhindert stale Success | erneut im Code nachvollzogen | bestätigt |
| stale Fehler wird ebenfalls verworfen | Generation schützt `_error` | bestätigt |
| Dispose-Test verbessert | echter In-Flight-Test vorhanden | bestätigt |
| FK-Indizes physisch vorhanden | erneut live bestätigt | bestätigt |
| Index-Migration fehlte in Live-Historie | durch neue Migration nachgetragen | behoben |
| `join_connection()` Race Condition | tatsächliche Funktion zeigte ungesperrtes Count/Insert | bestätigt und behoben |
| Realtime erzeugt teilweise Full Reloads | Code-/Architekturbefund bleibt bestehen | bestätigt |
| 61 lokale Migrationen vs. 38 live | aktueller Stand: 62 lokal vs. 40 live | historischer Drift weiterhin offen |
| große Assets | rund 67 MB weiterhin vorhanden | bestätigt |
| Flutter nicht ausführbar | weiterhin kein Flutter/Dart vorhanden | bestätigt |

---

## 5. AsyncController

### Aktueller Code

`lib/core/controllers/async_controller.dart` verwendet `_loadGeneration`.

Nur die aktuellste Generation darf:

- `_data` setzen
- `_error` setzen
- `_loading` beenden
- die abschließende Notification auslösen

Zusätzlich verhindert `_disposed` Notifications nach `dispose()`.

### Szenarien

#### A: A startet, B startet, B beendet zuerst

B bleibt autoritativ. A wird beim späteren Abschluss verworfen.

**Bewertung: bestanden auf Codeebene.**

#### B: A Fehler, B Erfolg

Der Fehler aus A wird wegen veralteter Generation verworfen.

**Bewertung: bestanden auf Codeebene.**

#### C: Dispose während In-Flight Request

Die Response darf intern noch eintreffen, aber keine Notification mehr auslösen.

Der Test prüft dieses Verhalten mit einem `Completer` und Listener.

**Bewertung: bestanden auf Testdesign-Ebene; Laufzeit nicht ausgeführt.**

#### D: Drei konkurrierende Requests

Zusätzlicher Test wurde aufgenommen. Der neueste Request muss unabhängig von Abschlussreihenfolge autoritativ bleiben.

**Bewertung: Test ergänzt.**

#### E: echte Cancellation

Es existiert weiterhin keine physische Cancellation des zugrunde liegenden Futures.

Die Implementierung verwendet Generation Invalidierung.

Das ist für die derzeitige Architektur ausreichend, solange `fetch()` keine nicht freigebbaren Ressourcen offen hält.

**Bewertung: kein akuter Änderungsbedarf.**

---

## 6. Regressionstest

`test/core/async_controller_test.dart` enthält jetzt:

- normalen Success-Fall
- Fehlernormalisierung
- stale Success gegen älteren Request
- Dispose während eines In-Flight Requests
- drei überlappende Requests
- stale Failure gegen neueren Success

Der Drei-Request-Test ist deterministisch, weil die Responses über `Completer` kontrolliert werden.

Der Test prüft weiterhin Verhalten statt nur Quelltextfragmente.

### Einschränkung

Die Tests wurden wegen fehlendem Flutter/Dart nicht tatsächlich ausgeführt.

**Testqualität: gut. Testlauf: nicht verifizierbar.**

---

## 7. `join_connection()` Race Condition

### Ursprünglicher Fehler

Die ursprüngliche Funktion führte sinngemäß aus:

```text
count members
if count >= 2 -> error
insert member
```

Ohne Sperre konnten zwei parallele Requests beide denselben Zwischenzustand sehen.

Die vorhandenen Constraints waren nicht ausreichend:

- `PRIMARY KEY(connection_id, user_id)` verhindert doppelte Kombinationen.
- `UNIQUE(user_id)` verhindert, dass derselbe Benutzer mehrfach Mitglied wird.
- Kein Constraint erzwingt jedoch direkt maximal zwei unterschiedliche Benutzer pro Connection.

### Umsetzung Audit 3

Die Funktion sperrt jetzt die Connection-Zeile:

```sql
select id
  into cid
from public.connections
where code = upper(trim(p_code))
for update;
```

Danach wird die Mitgliederzahl geprüft und der Insert ausgeführt.

Damit werden konkurrierende Joins derselben Connection serialisiert.

### Live-Verifikation

Die Live-Funktion enthält:

- `SECURITY DEFINER`
- `search_path=public`
- `FOR UPDATE`
- `authenticated` EXECUTE
- kein `anon` EXECUTE

### Bewertung

**P1 behoben.**

Ein paralleler Join-Test mit zwei realen Client-Sessions konnte in der verfügbaren Umgebung nicht als echter End-to-End-Test ausgeführt werden. Die Korrektur ist jedoch auf Datenbankebene deterministisch begründet.

---

## 8. Supabase-Indizes

Weiterhin vorhanden:

```text
idx_personal_decision_history_plan_id
  public.personal_decision_history(plan_id)

idx_personal_today_plans_recipe_id
  public.personal_today_plans(recipe_id)
```

Die Indizes entsprechen den zuvor identifizierten Foreign Keys.

Der Supabase Performance Advisor kann sie weiterhin als unbenutzt melden. Das ist angesichts der geringen tatsächlichen Last kein ausreichender Grund für eine Entfernung.

### Migration

Die ursprünglich lokale Migration wurde nicht einfach umgeschrieben.

Stattdessen wurde eine idempotente Migration:

`audit_add_missing_fk_indexes`

live nachgetragen.

Die lokale Datei wurde auf die tatsächlich von Supabase vergebene Migrationsversion synchronisiert.

---

## 9. Migration Audit

### Aktueller Zustand

- lokal: 62 SQL-Migrationen
- live: 40 Migrationseinträge

Die historische Divergenz besteht weiterhin.

Die beiden Audit-3-Änderungen sind jedoch jetzt in der Live-Historie vorhanden:

- `harden_join_connection_concurrency`
- `audit_add_missing_fk_indexes`

### Bewertung

Die Gesamt-Historie ist weiterhin nicht als vollständig reproduzierbare lineare Kette zu betrachten.

Ein frisches Projekt kann deshalb nicht allein durch blindes Ausführen aller lokalen Dateien als garantiert identisch zum Live-Projekt angesehen werden.

### Maßnahme

Keine rückwirkende Löschung oder Umnummerierung historischer Migrationen.

Empfehlung:

1. Live-Schema als Referenzzustand exportieren.
2. Alle lokalen Migrationen gegen den Live-Schemazustand abgleichen.
3. Eine dokumentierte Baseline/Reconciliation erstellen.
4. Danach ausschließlich neue Migrationen strikt synchron halten.

**Priorität: P1/P2 Reproduzierbarkeit.**

---

## 10. RLS / Security

Die geprüften Public-Tabellen haben weiterhin RLS aktiviert.

Die Policy-Struktur ist überwiegend auf:

- `auth.uid()`
- Ownership
- Connection Membership
- explizite Freigabe

aufgebaut.

### Anonymous Auth

Die Verwendung von Anonymous Auth ist nicht automatisch ein Sicherheitsfehler.

Entscheidend ist, dass die Policies den jeweiligen `auth.uid()` korrekt isolieren.

Die zweite Prüfung hatte bereits mehrere Advisor-Warnungen als Folge des Anonymous-Auth-Modells identifiziert.

Diese Warnungen bestehen weiterhin.

### SECURITY DEFINER

Supabase meldet weiterhin 20 `SECURITY DEFINER`-Funktionen als durch `authenticated` ausführbar.

Das ist für diese RPC-orientierte Architektur nicht automatisch eine Schwachstelle.

Für `join_connection()` wurde erneut bestätigt:

- `search_path=public`
- kein Execute für `anon`
- Execute für `authenticated`
- Autorisierung über `auth.uid()`
- Row-Lock gegen die relevante Connection

Die übrigen Funktionen wurden im Rahmen dieser dritten Prüfung nicht vollständig funktional in jedem denkbaren Parameterkombinationsraum fuzz-getestet. Daher wird keine pauschale Aussage getroffen, dass jede SECURITY-DEFINER-Funktion formal beweissicher ist.

---

## 11. RLS Policy Overlap

Der Supabase Performance Advisor meldet weiterhin mehrere permissive Policies, insbesondere bei:

- `recipes`
- `recipe_ingredients`
- `recipe_suggestions`

Die Policies erfüllen unterschiedliche fachliche Zugriffspfade.

Eine aggressive Zusammenlegung würde deshalb das Risiko bergen, Zugriffslogik zu verändern.

**Keine Änderung empfohlen.**

---

## 12. Realtime

Die zweite Prüfung wurde bestätigt:

- Realtime ist für relevante Collaboration-/Personal-Tabellen aktiviert.
- Listener werden grundsätzlich wieder entfernt.
- Mehrere Listener führen nach kleinen Änderungen komplette Reloads aus.

Das ist primär ein Performance-/Skalierungsthema.

Keine zentrale Realtime-Neuarchitektur wurde eingeführt.

**Priorität: P2, später messen und gezielt optimieren.**

---

## 13. Flutter-Architektur

Die bestehende Struktur bleibt grundsätzlich verwendbar:

```text
UI
→ Controller / State
→ Repository / Service
→ Supabase
```

Sie ist nicht überall konsequent umgesetzt.

Es gibt weiterhin:

- große Feature-Dateien
- lokale `setState()`-Zustände
- direkte Realtime-Zugriffe aus UI-nahen Schichten
- teilweise enge Kopplung von Navigation und UI

Diese Punkte sind technische Schulden, aber kein ausreichender Grund für eine Komplettmigration.

**Keine Architekturänderung in Audit 3.**

---

## 14. Query Audit

Im Projekt wurden zahlreiche Supabase-Zugriffe gefunden. Die Architektur enthält weiterhin Repository-basierte Datenzugriffe, daneben aber auch direkte Infrastrukturzugriffe in einzelnen Feature-Schichten.

Es wurde kein einzelnes Query-Muster gefunden, das einen sofortigen P0/P1-Umbau rechtfertigt.

N+1-/Full-Reload-Themen bleiben als P2-Kandidaten bestehen.

---

## 15. Async / Lifecycle

Die AsyncController-Absicherung ist verbessert.

Weiterhin zu beobachten:

- Streams
- Realtime Channels
- Lifecycle-Wechsel
- Full Reloads nach Events
- fehlende physische Cancellation

Kein weiterer lokaler Umbau wurde vorgenommen.

---

## 16. Assets / Performance

Die Asset-Menge liegt weiterhin bei ungefähr 67 MB.

Der größte Block besteht aus Hintergrundbildern.

Mehrere PNG-Dateien liegen oberhalb von 2 MB.

Das ist ein realer Performance-/Downloadkostenpunkt.

### Empfehlung

Später gezielt prüfen:

- WebP/AVIF
- Auflösung je Displaybedarf
- Kompression
- Caching

Nicht blind alle Assets konvertieren.

**Priorität: P2.**

---

## 17. Edge Functions

`restaurant-discovery` verwendet weiterhin `verify_jwt=false`, authentifiziert jedoch serverseitig im Handler.

Das ist nicht automatisch eine Auth-Bypass-Schwachstelle.

Der Punkt bleibt als Modernisierungs-/Missbrauchsschutz-Thema offen.

`generate-recipes` bleibt deaktiviert.

Keine Änderung an den Edge Functions im dritten Audit.

---

## 18. Dependency Audit

Es wurde keine Dependency allein aufgrund eines allgemeinen Aktualisierungswunsches verändert.

Ohne ausführbaren Flutter-/Dart-Toolchain-Lauf ist insbesondere eine belastbare Aussage über den tatsächlich aufgelösten Paketzustand und mögliche Build-Regressions nicht möglich.

**Keine Dependency-Änderung.**

---

## 19. Testarchitektur

Vorhanden:

- Unit-/Controller-nahe Tests
- Widget-/Feature-Tests
- Regression Tests

Nicht vorhanden:

- `integration_test/`

Source-basierte Regressionstests existieren weiterhin im Projekt. Sie können für bestimmte historische Regressionen nützlich sein, ersetzen aber keine Verhaltenstests.

Die Async-Regression wurde bereits auf Verhaltensebene verbessert.

**Empfehlung: schrittweise weitere kritische Source-Based Tests durch Verhaltenstests ersetzen. P2.**

---

## 20. Pflicht-Tabelle

| Befund | Audit 1 | Audit 2 | Audit 3 | Aktueller Zustand | Priorität | Maßnahme |
|---|---|---|---|---|---|---|
| AsyncController Race Condition | erkannt/gehärtet | bestätigt | erneut bestätigt | Generation schützt stale Responses | P1/P2 | beibehalten |
| Async Regression Test | hinzugefügt | erweitert | erneut erweitert | Verhaltenstest mit mehreren In-Flight Requests | P2 | beibehalten |
| `idx_personal_decision_history_plan_id` | hinzugefügt | live bestätigt | Migration nachgetragen | vorhanden + historisiert | P2 | beibehalten |
| `idx_personal_today_plans_recipe_id` | hinzugefügt | live bestätigt | Migration nachgetragen | vorhanden + historisiert | P2 | beibehalten |
| `join_connection()` Race | übersehen | entdeckt | bestätigt + behoben | Row-Lock aktiv | P1 | erledigt |
| Migration Drift | erkannt | bestätigt | erneut bestätigt | historischer Drift bleibt | P1/P2 | Reconciliation vorbereiten |
| RLS | geprüft | erneut geprüft | erneut geprüft | ownership-/membership-basiert | P1/P2 | keine pauschale Änderung |
| Anonymous Auth | bewertet | erneut bewertet | bestätigt | bewusstes Modell | P2 | dokumentieren |
| SECURITY DEFINER | geprüft | erneut geprüft | erneut geprüft | 20 exposed RPCs als Advisor-Warnung | P1/P2 | funktional weiter prüfen |
| Realtime | geprüft | Full Reloads erkannt | bestätigt | korrekt, aber teilweise ineffizient | P2 | später optimieren |
| Asset-Größe | erkannt | bestätigt | bestätigt | ca. 67 MB | P2 | gezielt optimieren |
| Edge Functions | geprüft | bestätigt | bestätigt | `restaurant-discovery` serverseitig auth | P2 | später modernisieren |

---

## 21. Konkrete Änderungen in Audit 3

### 21.1 `join_connection()` härten

**Problem:** Nicht atomare Mitgliederzählung vor Insert.

**Ursache:** Keine Sperre auf Connection-Ebene.

**Betroffene DB-Funktion:** `public.join_connection(text)`.

**Lösung:** `SELECT ... FOR UPDATE` auf der Connection-Zeile.

**Aufwand:** klein.

**Risiko:** niedrig bis mittel.

**Nutzen:** verhindert konkurrierende Joins derselben Connection während der Count/Insert-Sequenz.

**Status:** live angewendet und verifiziert.

### 21.2 Index-Migration historisieren

**Problem:** Physisch vorhandene Audit-Indizes waren nicht in der Live-Migrationshistorie vertreten.

**Lösung:** idempotente Migration `audit_add_missing_fk_indexes` angewendet.

**Aufwand:** klein.

**Risiko:** niedrig.

**Status:** live angewendet und verifiziert.

### 21.3 Async-Regressionstest erweitern

**Problem:** Zwei Requests waren abgedeckt, drei parallele Requests nicht explizit.

**Lösung:** deterministischer Drei-Request-Test mit `Completer`.

**Aufwand:** klein.

**Status:** Code geändert; Ausführung mangels Flutter nicht verifiziert.

---

## 22. Bewusst nicht geändert

Nicht geändert wurden:

- vollständige Clean-Architecture-Migration
- kompletter State-Management-Wechsel
- aggressive RLS-Policy-Zusammenlegung
- Entfernung von SECURITY-DEFINER-Funktionen ohne Funktionsanalyse
- aggressive Indexbereinigung
- vollständige Realtime-Neuarchitektur
- pauschale Asset-Konvertierung
- Dependency-Upgrade
- Edge-Function-Umbau
- rückwirkende Migration-Umschreibung

Für diese Punkte fehlte entweder ein ausreichend konkreter Nutzen oder die Änderung wäre im Verhältnis zum Risiko zu groß.

---

## 23. Behoben

1. `join_connection()` Race Condition durch Row-Lock abgesichert.
2. Die beiden Audit-FK-Indizes sind jetzt zusätzlich als Live-Migration historisiert.
3. Async-Regressionstest um einen deterministischen Drei-Request-Fall erweitert.
4. Zweite-Prüfungs-Befunde zu AsyncController und Indexdefinitionen erneut validiert.

---

## 24. Offen

### P1/P2 Migration Drift

Die historische Repository-/Live-Migrationskette bleibt auseinanderentwickelt.

**Grund:** Eine rückwirkende Bereinigung wäre riskanter als die bestehende Drift.

**Nächster Schritt:** Schema-/Migration-Reconciliation als eigenes Release-Thema.

### P2 Realtime Full Reloads

**Grund:** aktuell kein nachgewiesener Funktionsfehler.

**Nächster Schritt:** Event-/Reload-Messung und gezielte Optimierung.

### P2 Asset-Größe

**Grund:** Performanceproblem, aber kein kritischer Produktionsfehler.

**Nächster Schritt:** gezielte Bildoptimierung mit Vorher-/Nachher-Vergleich.

### P2 Testarchitektur

**Grund:** keine Integrationstests und einige Source-Based Tests.

**Nächster Schritt:** kritische End-to-End-/Repository-Flows schrittweise als Verhaltenstests abdecken.

### Flutter-Verifikation

**Grund:** Flutter/Dart fehlen in der Prüfungsumgebung.

**Nächster Schritt:** Audit in echter Flutter-Toolchain wiederholen und `analyze`/`test`/Coverage ausführen.

---

## 25. Nicht erforderlich

Folgende Änderungen sind aufgrund der dritten Prüfung aktuell nicht erforderlich:

- Entfernung aller SECURITY-DEFINER-Funktionen
- Abschalten von Anonymous Auth ohne Produktentscheidung
- komplette Clean-Architecture-Migration
- kompletter Wechsel des State-Management-Frameworks
- aggressive Indexbereinigung
- komplette Realtime-Neuimplementierung
- pauschale Umwandlung aller Assets
- vollständiges Dependency-Upgrade

---

## 26. Endgültige technische Bewertung

Die dritte Prüfung bestätigt, dass die wesentlichen Verbesserungen aus dem Async-Bereich technisch sinnvoll sind. Gleichzeitig zeigt sie, dass die zweite Prüfung eine echte Datenintegritätslücke zwar erkannt, aber bewusst noch nicht umgesetzt hatte.

Diese Lücke wurde jetzt mit einer kleinen, DB-seitigen Änderung geschlossen.

Die Migration-Historie bleibt das größte strukturelle Reproduzierbarkeitsproblem. Die beiden Audit-Migrationen sind jetzt live historisiert, aber die historische Divergenz zwischen 62 lokalen Dateien und 40 Live-Migrationseinträgen ist damit nicht automatisch gelöst.

Der aktuelle Zustand rechtfertigt keinen Komplettumbau.

Die technisch sinnvolle Reihenfolge für weitere Arbeiten ist:

1. Migration-/Schema-Reconciliation durchführen.
2. Flutter-Toolchain herstellen und vollständigen Testlauf ausführen.
3. kritische Connect-/Sharing-Flows als echte Verhaltenstests abdecken.
4. Realtime-Full-Reloads messen und gezielt reduzieren.
5. Assets optimieren.

Der zentrale Grundsatz bleibt:

> Nicht möglichst viel ändern, sondern nur das ändern, dessen technischer Nutzen nachweisbar ist.

---

## 27. Verifikationsgrenzen

Nicht behauptet werden können:

- erfolgreicher Flutter-Testlauf
- erfolgreicher Flutter-Analyze-Lauf
- Coverage-Ergebnis
- echter paralleler Multi-Client-End-to-End-Test
- vollständige formale Verifikation aller SECURITY-DEFINER-RPCs
- vollständige Reconciliation aller historischen Migrationen

Diese Punkte sind im aktuellen Bericht bewusst als offen bzw. nicht verifizierbar ausgewiesen.
