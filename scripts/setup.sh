#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

FULL=0
if [[ "${1:-}" == "--full" ]]; then
  FULL=1
elif [[ $# -gt 0 ]]; then
  echo "Verwendung: ./setup.sh [--full]" >&2
  exit 2
fi

require_flutter
require_project_structure

# The config is machine-local and survives replacing this project with a new ZIP.
load_local_env
configure_firebase_if_needed

echo "=== together Setup ==="
echo "→ Flutter"
"$FLUTTER_BIN" --version | sed -n '1,2p'

echo "→ Dependencies"
if ! "$FLUTTER_BIN" pub get --enforce-lockfile; then
  echo "⚠️ pubspec.lock passt noch nicht zum aktuellen Pubspec."
  echo "→ Lockfile einmalig neu auflösen"
  "$FLUTTER_BIN" pub get
  echo "→ Aufgelöstes Lockfile prüfen"
  "$FLUTTER_BIN" pub get --enforce-lockfile
fi

echo "→ App-Icon"
"$FLUTTER_BIN" pub run flutter_launcher_icons --file flutter_launcher_icons.yaml

echo "→ Repository-Hygiene"
bash ./scripts/check_repository.sh
echo "→ Architektur-Audit"
bash ./scripts/check_architecture.sh
echo "→ Flutter Analyze"
"$FLUTTER_BIN" analyze
echo "→ Flutter Tests"
"$FLUTTER_BIN" test

if [[ "$FULL" -eq 1 ]]; then
  echo "→ Vollständige Release-Verifikation"
  bash ./scripts/verify_release.sh
fi

echo
echo "✓ Setup erfolgreich"
echo "  Konfiguration: $TOGETHER_ENV_FILE"
echo "  Start:  ./scripts/run_app.sh"
echo "  Build:  ./scripts/build_release.sh"
if [[ "$FULL" -eq 0 ]]; then
  echo "  Vollprüfung: ./setup.sh --full"
fi
