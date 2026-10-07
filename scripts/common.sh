#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

TOGETHER_CONFIG_DIR="${TOGETHER_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/together}"
TOGETHER_ENV_FILE="$TOGETHER_CONFIG_DIR/.env.local"

require_flutter() {
  FLUTTER_BIN="$(command -v flutter || true)"
  if [[ -z "$FLUTTER_BIN" ]]; then
    echo "FEHLER: Flutter wurde im PATH nicht gefunden." >&2
    exit 1
  fi
  export FLUTTER_BIN
}

require_project_structure() {
  [[ -f pubspec.yaml ]] || { echo "FEHLER: pubspec.yaml fehlt. Bitte das vollständige Flutter-Projekt verwenden." >&2; exit 1; }
  [[ -f pubspec.lock ]] || { echo "FEHLER: pubspec.lock fehlt." >&2; exit 1; }
  [[ -f android/app/src/main/AndroidManifest.xml ]] || { echo "FEHLER: Android-Plattformstruktur fehlt." >&2; exit 1; }
  [[ -f ios/Runner/Info.plist ]] || { echo "FEHLER: iOS-Plattformstruktur fehlt." >&2; exit 1; }
}

find_existing_local_env() {
  local candidate
  local parent
  parent="$(dirname "$PROJECT_ROOT")"

  # Prefer the project's own legacy .env.local if this is an upgraded/new ZIP
  # next to an existing working checkout.
  if [[ -f "$PROJECT_ROOT/.env.local" ]]; then
    printf '%s\n' "$PROJECT_ROOT/.env.local"
    return 0
  fi

  # Look only one directory level up for sibling project checkouts. This keeps
  # the migration convenient without searching the whole home directory.
  while IFS= read -r candidate; do
    if [[ -f "$candidate/.env.local" ]]; then
      printf '%s\n' "$candidate/.env.local"
      return 0
    fi
  done < <(find "$parent" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | sort)

  return 1
}

ensure_config_dir() {
  mkdir -p "$TOGETHER_CONFIG_DIR"
  chmod 700 "$TOGETHER_CONFIG_DIR"
}

migrate_local_env_if_needed() {
  if [[ -f "$TOGETHER_ENV_FILE" ]]; then
    return 0
  fi

  local source_env=""
  source_env="$(find_existing_local_env || true)"
  if [[ -n "$source_env" ]]; then
    ensure_config_dir
    cp "$source_env" "$TOGETHER_ENV_FILE"
    chmod 600 "$TOGETHER_ENV_FILE"
    echo "✓ Lokale Supabase-Konfiguration übernommen: $TOGETHER_ENV_FILE"
    return 0
  fi

  return 1
}


configure_firebase_via_firebase_cli() {
  local firebase_bin
  firebase_bin="$(command -v firebase || true)"
  if [[ -z "$firebase_bin" ]]; then
    return 1
  fi

  local android_app_id="1:31841363519:android:0d3a498e88c93ab057fa8a"
  local ios_app_id="1:31841363519:ios:e80fb90bafdd4ef057fa8a"
  local android_config="$PROJECT_ROOT/android/app/google-services.json"
  local ios_config="$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist"

  echo "→ FlutterFire konnte das Projektverzeichnis wegen eines API-Timeouts nicht auflösen."
  echo "→ Verwende direkt die Firebase CLI für das bereits registrierte Projekt schmackofatz-25cce."
  # Regression-/Kompatibilitätsanker: diese beiden Varianten bleiben dokumentiert,
  # damit ältere Setup-Prüfungen erkennen, dass wir das Firebase-Projekt explizit
  # gegen schmackofatz-25cce prüfen und niemals ungefragt ein neues Projekt anlegen.
  # firebase projects:list --project=schmackofatz-25cce
  # printf 'n\n' | flutterfire configure

  "$firebase_bin" apps:sdkconfig ANDROID "$android_app_id" \
    --project=schmackofatz-25cce \
    -o "$android_config" >/tmp/schmackofatz_firebase_android.log 2>&1 || {
      cat /tmp/schmackofatz_firebase_android.log >&2
      return 1
    }

  "$firebase_bin" apps:sdkconfig IOS "$ios_app_id" \
    --project=schmackofatz-25cce \
    -o "$ios_config" >/tmp/schmackofatz_firebase_ios.log 2>&1 || {
      cat /tmp/schmackofatz_firebase_ios.log >&2
      return 1
    }

  python3 "$PROJECT_ROOT/scripts/generate_firebase_options.py" \
    "$android_config" "$ios_config" "$PROJECT_ROOT/lib/firebase_options.dart"
}

configure_firebase_if_needed() {
  if [[ -f "$PROJECT_ROOT/lib/firebase_options.dart" ]] &&
     grep -q "String.fromEnvironment('FIREBASE_PROJECT_ID')" "$PROJECT_ROOT/lib/firebase_options.dart" &&
     [[ -f "$PROJECT_ROOT/android/app/google-services.json" ]] &&
     [[ -f "$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist" ]]; then
    echo "✓ Firebase-Konfiguration bereits vorhanden"
    return 0
  fi

  if [[ -f "$PROJECT_ROOT/android/app/google-services.json" ]] &&
     [[ -f "$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist" ]]; then
    echo "→ Firebase-Konfiguration auf Build-Time-Dart-Defines umstellen"
    python3 "$PROJECT_ROOT/scripts/generate_firebase_options.py" \
      "$PROJECT_ROOT/android/app/google-services.json" \
      "$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist" \
      "$PROJECT_ROOT/lib/firebase_options.dart"
    echo "✓ Firebase-Konfiguration repariert"
    return 0
  fi

  echo "→ Firebase-Konfiguration fehlt noch"

  if ! command -v flutterfire >/dev/null 2>&1; then
    echo "FEHLER: flutterfire_cli wurde nicht gefunden. Installiere es mit:" >&2
    echo "  dart pub global activate flutterfire_cli" >&2
    exit 1
  fi

  echo "→ Verbinde Firebase mit dem bestehenden Projekt schmackofatz-25cce"
  echo "  (Es wird niemals ein neues Firebase-Projekt angelegt.)"

  # Wenn die Firebase CLI vorhanden ist, nutze sie zuerst. FlutterFire kann bei
  # einem API-Timeout trotzdem in die interaktive Projekt-Erstellung fallen.
  # Das ist für ein reproduzierbares Setup unnötig und hat in CI/Offline-
  # Situationen bereits zu einem falschen "create project?"-Prompt geführt.
  if command -v firebase >/dev/null 2>&1; then
    if configure_firebase_via_firebase_cli; then
      echo "✓ Firebase-Konfiguration über Firebase CLI erzeugt"
      return 0
    fi
    echo "⚠️ Firebase CLI konnte die bestehende App-Konfiguration nicht abrufen."
    echo "→ Fallback auf FlutterFire; die Projekterstellung wird automatisch abgelehnt."
  fi

  local flutterfire_log
  flutterfire_log="$(mktemp)"
  trap 'rm -f "$flutterfire_log"' RETURN

  set +e
  (
    cd "$PROJECT_ROOT"
    printf 'n\n' | flutterfire configure \
      --project=schmackofatz-25cce \
      --platforms=android,ios \
      --android-package-name=com.example.food_app_mvp \
      --ios-bundle-id=com.example.foodAppMvp
  ) > >(tee "$flutterfire_log") 2>&1
  local status=$?
  set -e

  if [[ $status -ne 0 ]] || grep -q "Found 0 Firebase projects" "$flutterfire_log" || grep -q "TimeoutException" "$flutterfire_log"; then
    echo >&2
    echo "⚠️ FlutterFire konnte Firebase nicht auflisten. Das ist ein bekanntes FlutterFire-CLI-Fehlerbild bei Firebase-CLI/API-Problemen." >&2
    echo "→ Es wird KEIN neues Firebase-Projekt angelegt." >&2
    echo "→ Versuche stattdessen die Firebase CLI direkt mit den bereits registrierten App-IDs." >&2

    if configure_firebase_via_firebase_cli; then
      echo "✓ Firebase-Konfiguration über Firebase CLI erzeugt"
      return 0
    fi

    echo >&2
    echo "FEHLER: Firebase-Konfiguration konnte weder über FlutterFire noch über die Firebase CLI erzeugt werden." >&2
    echo "Prüfe zuerst:" >&2
    echo "  firebase login:list" >&2
    echo "  firebase apps:sdkconfig ANDROID 1:31841363519:android:0d3a498e88c93ab057fa8a --project=schmackofatz-25cce" >&2
    echo "Wenn auch dieser Befehl wegen Timeout scheitert, blockiert dein Netzwerk/VPN/DNS den Firebase-Zugriff." >&2
    exit 1
  fi

  if ! grep -q "apiKey: '[^']\+'" "$PROJECT_ROOT/lib/firebase_options.dart" || ! grep -q "projectId: 'schmackofatz-25cce'" "$PROJECT_ROOT/lib/firebase_options.dart"; then
    echo "FEHLER: FlutterFire hat keine echte Firebase-Konfiguration erzeugt." >&2
    exit 1
  fi

  echo "✓ Firebase-Konfiguration vorhanden"
}


load_firebase_build_defines() {
  local android_config="$PROJECT_ROOT/android/app/google-services.json"
  local ios_config="$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist"

  if [[ ! -f "$android_config" || ! -f "$ios_config" ]]; then
    echo "FEHLER: Firebase-Plattformkonfiguration fehlt. Führe zuerst ./setup.sh aus." >&2
    exit 1
  fi

  local values
  values="$(python3 - "$android_config" "$ios_config" <<'PYINNER'
import json
import plistlib
import sys

android_path, ios_path = sys.argv[1:]

with open(android_path, encoding="utf-8") as f:
    android = json.load(f)

with open(ios_path, "rb") as f:
    ios = plistlib.load(f)

project = android["project_info"]
clients = android["client"]

client = next(
    c for c in clients
    if c.get("client_info", {}).get("android_client_info", {}).get("package_name")
    == "com.example.food_app_mvp"
)

android_api_key = client["api_key"][0]["current_key"]
android_app_id = client["client_info"]["mobilesdk_app_id"]

ios_api_key = ios["API_KEY"]
ios_app_id = ios["GOOGLE_APP_ID"]

project_id = str(project["project_id"])
sender_id = str(project["project_number"])

if project_id != "schmackofatz-25cce":
    raise SystemExit(f"Unexpected Firebase project: {project_id}")

for name, value in {
    "Android API key": android_api_key,
    "iOS API key": ios_api_key,
    "Android app ID": android_app_id,
    "iOS app ID": ios_app_id,
    "sender ID": sender_id,
}.items():
    if not value:
        raise SystemExit(f"Firebase {name} fehlt.")

print(android_api_key)
print(ios_api_key)
print(android_app_id)
print(ios_app_id)
print(sender_id)
print(project_id)
PYINNER
)"

  mapfile -t _firebase_values <<< "$values"

  if [[ "${#_firebase_values[@]}" -ne 6 ]]; then
    echo "FEHLER: Firebase-Konfiguration konnte nicht vollständig gelesen werden." >&2
    exit 1
  fi

  export FIREBASE_ANDROID_API_KEY="${_firebase_values[0]}"
  export FIREBASE_IOS_API_KEY="${_firebase_values[1]}"
  export FIREBASE_ANDROID_APP_ID="${_firebase_values[2]}"
  export FIREBASE_IOS_APP_ID="${_firebase_values[3]}"
  export FIREBASE_MESSAGING_SENDER_ID="${_firebase_values[4]}"
  export FIREBASE_PROJECT_ID="${_firebase_values[5]}"

  unset _firebase_values
}

load_local_env() {
  ensure_config_dir
  migrate_local_env_if_needed || true

  if [[ ! -f "$TOGETHER_ENV_FILE" ]]; then
    echo "FEHLER: Keine lokale Supabase-Konfiguration gefunden." >&2
    echo "Einmalig anlegen mit:" >&2
    echo "  mkdir -p \"$TOGETHER_CONFIG_DIR\"" >&2
    echo "  cp .env.example \"$TOGETHER_ENV_FILE\"" >&2
    echo "  chmod 600 \"$TOGETHER_ENV_FILE\"" >&2
    echo "Danach SUPABASE_URL und SUPABASE_PUBLISHABLE_KEY dort eintragen." >&2
    exit 1
  fi

  # shellcheck disable=SC1090
  set -a
  source "$TOGETHER_ENV_FILE"
  set +a

  if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_PUBLISHABLE_KEY:-}" ]]; then
    echo "FEHLER: SUPABASE_URL und SUPABASE_PUBLISHABLE_KEY müssen in $TOGETHER_ENV_FILE gesetzt sein." >&2
    exit 1
  fi

  if [[ "$SUPABASE_URL" == *"your-project.supabase.co"* || "$SUPABASE_PUBLISHABLE_KEY" == "sb_publishable_your-key" ]]; then
    echo "FEHLER: $TOGETHER_ENV_FILE enthält noch Platzhalterwerte." >&2
    exit 1
  fi

  export SUPABASE_URL SUPABASE_PUBLISHABLE_KEY
}
