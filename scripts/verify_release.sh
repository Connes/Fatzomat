#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

require_flutter
require_project_structure
load_local_env

if [[ -f android/key.properties ]]; then
  echo "→ private release signing: eigener Keystore"
else
  echo "→ private release signing: Flutter-Debug-Key (kein Store-Release)"
fi

echo "=== Schmackofatz Release Verification ==="
echo "→ repository hygiene"
bash ./scripts/check_repository.sh
echo "→ architecture audit"
bash ./scripts/check_architecture.sh
echo "→ flutter pub get --enforce-lockfile"
"$FLUTTER_BIN" pub get --enforce-lockfile
echo "→ flutter analyze"
"$FLUTTER_BIN" analyze
echo "→ flutter test"
"$FLUTTER_BIN" test
echo "→ flutter build apk --debug"
"$FLUTTER_BIN" build apk --debug \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY"
echo "→ flutter build apk --release"
"$FLUTTER_BIN" build apk --release \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY"

echo "✓ Release-Verifikation erfolgreich"
