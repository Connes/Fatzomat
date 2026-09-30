#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

REPORT_DIR="$PROJECT_ROOT/reports"
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/diagnose_$(date +%Y%m%d_%H%M%S).txt"
exec > >(tee "$REPORT_FILE") 2>&1

FAIL=0
section() { echo; echo "========================================"; echo " $1"; echo "========================================"; }
ok() { echo "✓ $1"; }
warn() { echo "⚠ $1"; }
fail() { echo "✗ $1"; FAIL=1; }
run_check() {
  local label="$1"; shift
  echo "→ $label"
  if "$@"; then ok "$label"; else fail "$label"; fi
}

section "TOGETHER DIAGNOSE"
echo "Zeit: $(date -Is)"
echo "Projekt: $PROJECT_ROOT"

section "Flutter / Dart"
if command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="$(command -v flutter)"
  export FLUTTER_BIN
  "$FLUTTER_BIN" --version | sed -n '1,4p'
  run_check "flutter doctor" "$FLUTTER_BIN" doctor -v
else
  fail "Flutter nicht im PATH"
fi

section "Projektstruktur"
if require_project_structure; then ok "Projektstruktur"; else FAIL=1; fi

section "Supabase-Konfiguration"
if load_local_env; then
  ok "Lokale Supabase-Konfiguration vorhanden"
  echo "SUPABASE_URL: ${SUPABASE_URL%%/}"
  echo "SUPABASE_PUBLISHABLE_KEY: vorhanden (Wert wird nicht ausgegeben)"
else
  fail "Supabase-Konfiguration"
fi

section "Dependencies / statische Checks"
if [[ -n "${FLUTTER_BIN:-}" ]]; then
  run_check "pub get --enforce-lockfile" "$FLUTTER_BIN" pub get --enforce-lockfile
  run_check "flutter analyze" "$FLUTTER_BIN" analyze
  run_check "flutter test" "$FLUTTER_BIN" test
  run_check "Repository-Hygiene" "$PROJECT_ROOT/scripts/check_repository.sh"
  run_check "Architektur-Audit" "$PROJECT_ROOT/scripts/check_architecture.sh"
fi

section "Android / ADB"
if command -v adb >/dev/null 2>&1; then
  run_check "ADB erreichbar" adb start-server
  adb devices -l || true
else
  warn "adb nicht im PATH gefunden"
fi

section "Flutter / Dart Prozesse"
if pgrep -af '(^|/)(flutter|dart)( |$)' >/tmp/together_flutter_processes.$$ 2>/dev/null; then
  cat /tmp/together_flutter_processes.$$
  warn "Flutter/Dart-Prozesse laufen. Das ist nicht automatisch ein Fehler."
  rm -f /tmp/together_flutter_processes.$$
else
  ok "Keine alten Flutter/Dart-Prozesse gefunden"
fi

section "DDS / lokale Ports"
if command -v ss >/dev/null 2>&1; then
  echo "Aktive LISTEN-Ports im lokalen Bereich:"
  ss -ltnp 2>/dev/null | grep -E '127\.0\.0\.1:(4[0-9]{4}|5[0-9]{4})|127\.0\.0\.1:([0-9]{4,5})' | head -80 || true
else
  warn "ss nicht verfügbar"
fi

section "Typische Flutter-/DDS-Indikatoren"
FOUND=0
for pattern in 'DartDevelopmentServiceException' 'WebSocketChannelException' 'Connection refused' 'SocketException' 'GradleException' 'Exception:'; do
  if grep -R --exclude-dir=.git --exclude='*.lock' -nE "$pattern" "$REPORT_DIR" 2>/dev/null | head -10; then
    FOUND=1
  fi
done
if [[ "$FOUND" -eq 0 ]]; then ok "Keine bekannten Fehlerindikatoren im Diagnosebericht"; else warn "Fehlerindikatoren gefunden, siehe Diagnosebericht"; fi

section "Ergebnis"
echo "Diagnosebericht: $REPORT_FILE"
if [[ "$FAIL" -eq 0 ]]; then
  echo "✓ Grundprüfung erfolgreich"
else
  echo "✗ Mindestens eine Prüfung ist fehlgeschlagen"
fi
exit "$FAIL"
