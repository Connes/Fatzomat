# Teststrategie

## Ebenen

1. Repository Hygiene
2. Static Analysis
3. Unit Tests
4. Widget Tests
5. Database/Migration Tests
6. RLS/Security Tests
7. Integration Tests
8. Realtime Tests
9. Concurrency Tests
10. Multi-Client E2E
11. Build Verification
12. Staging Smoke Tests

## Aktueller Zustand

Die bestehende Flutter-Testbasis ist umfangreich, aber aktuell existiert kein `integration_test/`-Bestand. Die aktuelle autonome Runtime kann Flutter Tests nicht ausführen, weil Flutter in der Umgebung nicht installiert ist.

## Testprinzip

Ein Test gilt nur als erfolgreich, wenn er tatsächlich ausgeführt wurde. Source-basierte Regressionstests sind Architekturregressionen und ersetzen keine Runtime-/E2E-Tests.
