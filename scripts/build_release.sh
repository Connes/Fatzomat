#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

require_flutter
require_project_structure
load_local_env

if [[ -f android/key.properties ]]; then
  echo "→ Private Release-Signierung: eigener Keystore"
else
  echo "→ Private Release-Signierung: Flutter-Debug-Key (kein Store-Release)"
fi

"$FLUTTER_BIN" build apk --release \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY" \
  "$@"

echo
echo "✓ Release-APK: build/app/outputs/flutter-apk/app-release.apk"
