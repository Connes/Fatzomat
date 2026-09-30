#!/usr/bin/env bash
set -euo pipefail

fail=0
for forbidden in .env.local .env.production .env.prod; do
  if [[ -e "$forbidden" ]]; then
    echo "FEHLER: $forbidden darf nicht im Repository liegen." >&2
    fail=1
  fi
done

if [[ -e .github/workflows/ci.yml ]]; then
  echo "FEHLER: Doppelter CI-Workflow ist nicht erlaubt." >&2
  fail=1
fi
# Flutter/IDE erzeugen diese Dateien während `flutter pub get`, beim Icon-
# Generator oder beim Öffnen des Projekts. Sie dürfen deshalb lokal vorhanden
# sein. Entscheidend ist, dass sie nicht versioniert werden.
for generated in android/local.properties .flutter-plugins-dependencies .idea/workspace.xml; do
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git ls-files --error-unmatch "$generated" >/dev/null 2>&1; then
    echo "FEHLER: Lokales/generated Artefakt $generated ist versioniert und muss aus dem Repository entfernt werden." >&2
    fail=1
  fi
done

if [[ -f start_setup.sh ]]; then
  echo "FEHLER: Veralteter Setup-Einstieg start_setup.sh gefunden." >&2
  fail=1
fi

if [[ ! -f pubspec.lock ]]; then
  echo "FEHLER: pubspec.lock fehlt. In der Flutter-Umgebung 'flutter pub get' ausführen und versionieren." >&2
  fail=1
fi

if [[ ! -f android/app/src/main/AndroidManifest.xml || ! -f ios/Runner/Info.plist ]]; then
  echo "FEHLER: Android-/iOS-Plattformstruktur fehlt." >&2
  fail=1
fi

if [[ $fail -ne 0 ]]; then exit 1; fi
echo "✓ Repository-Hygiene OK"
