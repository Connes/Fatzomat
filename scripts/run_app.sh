#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

require_flutter
require_project_structure
load_local_env
configure_firebase_if_needed
load_firebase_build_defines

exec "$FLUTTER_BIN" run \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define="FIREBASE_ANDROID_API_KEY=$FIREBASE_ANDROID_API_KEY" \
  --dart-define="FIREBASE_IOS_API_KEY=$FIREBASE_IOS_API_KEY" \
  --dart-define="FIREBASE_ANDROID_APP_ID=$FIREBASE_ANDROID_APP_ID" \
  --dart-define="FIREBASE_IOS_APP_ID=$FIREBASE_IOS_APP_ID" \
  --dart-define="FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID" \
  --dart-define="FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID" \
  "$@"
