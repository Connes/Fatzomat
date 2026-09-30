#!/usr/bin/env bash
set -euo pipefail

FLUTTER_BIN="$(command -v flutter || true)"
if [[ -z "$FLUTTER_BIN" ]]; then
  echo "FEHLER: Flutter wurde im PATH nicht gefunden." >&2
  exit 1
fi

if [[ ! -f pubspec.lock ]]; then
  echo "FEHLER: pubspec.lock fehlt. 'flutter pub get' ausführen und die Lockdatei committen." >&2
  exit 1
fi

echo "=== Dependency policy ==="
"$FLUTTER_BIN" pub get --enforce-lockfile
echo "→ flutter pub outdated"
"$FLUTTER_BIN" pub outdated
