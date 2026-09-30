# Autonomous Development Readiness

## Ziel

Dieses Projekt soll so reproduzierbar werden, dass Entwicklung, Tests, Backend-Änderungen und Staging-Verifikation weitgehend autonom durchgeführt werden können.

## Aktueller verifizierter Stand

- Flutter-Projekt vorhanden.
- CI verwendet Flutter 3.47.2 stable.
- 63 lokale SQL-Migrationen vorhanden.
- 64 Dart-Testdateien vorhanden.
- Aktuell kein `integration_test/`-Verzeichnis vorhanden.
- Supabase-Projekt `MVP` ist als aktive Umgebung vorhanden.
- Eine getrennte Staging-Umgebung ist in der aktuellen Projektkonfiguration nicht verifiziert.
- Die aktuelle Ausführungsumgebung enthält kein Flutter, Dart, Supabase CLI, Docker oder Android Debug Bridge.

## Readiness Check

```bash
./scripts/check_autonomous_readiness.sh
```

Der Check unterscheidet zwischen `PASS`, `WARN` und `BLOCK`. Ein fehlendes Runtime-Tool wird nicht als theoretisch vorhanden betrachtet.

## Zielumgebungen

```text
LOCAL  -> TEST  -> STAGING  -> RELEASE CANDIDATE -> HUMAN APPROVAL -> PRODUCTION
```

Production bleibt von autonomer Schreib-/Deploy-Automation getrennt.

## Priorisierte Restarbeiten

1. Reproduzierbare Flutter-/Android-Toolchain verfügbar machen.
2. Lokale Supabase-/PostgreSQL-Runtime bereitstellen.
3. Alle 63 Migrationen auf einer frischen lokalen Datenbank replayen.
4. `supabase/tests/smoke.sql` gegen das Replay ausführen.
5. Integration Tests ergänzen.
6. Zwei unabhängige Testbenutzer für Multi-Client-Szenarien bereitstellen.
7. Realtime- und Concurrency-Tests tatsächlich ausführen.
8. Separate Staging-Umgebung einrichten.
9. iOS über einen macOS CI Runner verifizieren.
10. GitHub/CI so anbinden, dass ein autonomer Branch->CI->PR-Zyklus möglich ist.
