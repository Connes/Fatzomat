# Diagnose und Start

## Schnellstart

```bash
./setup.sh
./run.sh
```

## Diagnose

```bash
./diagnose.sh
```

Der Diagnosebericht wird unter `reports/` gespeichert. Secrets werden nicht ausgegeben.

Die Diagnose prüft Flutter/Dart, Flutter Doctor, Projektstruktur, zentrale Supabase-Konfiguration, Dependencies, Analyze, Tests, Repository-Hygiene, Architektur-Audit, ADB, laufende Flutter/Dart-Prozesse und lokale Ports.

## Release

```bash
./release.sh
```

Das ist der vollständige Release-Check mit Debug- und Release-APK-Build.
