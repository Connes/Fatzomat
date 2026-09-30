#!/usr/bin/env bash
set -u

# Reports readiness for autonomous development without pretending that missing
# runtime components are available. Exit 0 only when all mandatory local checks
# are executable; otherwise exit 2 (BLOCKED).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

pass=0
warn=0
block=0

check_cmd() {
  local label="$1" cmd="$2" level="$3"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'PASS  %-28s %s\n' "$label" "$(command -v "$cmd")"
    pass=$((pass+1))
  else
    printf '%-5s %-28s %s\n' "$level" "$label" "not available"
    if [[ "$level" == "BLOCK" ]]; then block=$((block+1)); else warn=$((warn+1)); fi
  fi
}

check_file() {
  local label="$1" path="$2" level="$3"
  if [[ -f "$path" ]]; then
    printf 'PASS  %-28s %s\n' "$label" "$path"
    pass=$((pass+1))
  else
    printf '%-5s %-28s %s\n' "$level" "$label" "$path missing"
    if [[ "$level" == "BLOCK" ]]; then block=$((block+1)); else warn=$((warn+1)); fi
  fi
}

check_dir() {
  local label="$1" path="$2" level="$3"
  if [[ -d "$path" ]]; then
    printf 'PASS  %-28s %s\n' "$label" "$path"
    pass=$((pass+1))
  else
    printf '%-5s %-28s %s\n' "$level" "$label" "$path missing"
    if [[ "$level" == "BLOCK" ]]; then block=$((block+1)); else warn=$((warn+1)); fi
  fi
}

printf '%s\n' '=== Schmackofatz autonomous development readiness ==='
printf '%s\n' "Project: $ROOT_DIR"
printf '%s\n\n' "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

check_cmd 'Flutter SDK' flutter BLOCK
check_cmd 'Dart SDK' dart BLOCK
check_cmd 'Java/JDK' java BLOCK
check_cmd 'Git' git BLOCK
check_cmd 'Supabase CLI' supabase BLOCK
check_cmd 'Docker' docker BLOCK
check_cmd 'ADB' adb WARN

check_file 'pubspec.yaml' pubspec.yaml BLOCK
check_file 'pubspec.lock' pubspec.lock BLOCK
check_dir 'Flutter source' lib BLOCK
check_dir 'Tests' test BLOCK
check_dir 'Supabase migrations' supabase/migrations BLOCK
check_file 'Supabase smoke tests' supabase/tests/smoke.sql BLOCK
check_file 'CI workflow' .github/workflows/flutter.yml BLOCK

migration_count=$(find supabase/migrations -type f -name '*.sql' 2>/dev/null | wc -l | tr -d ' ')
printf 'PASS  %-28s %s migrations\n' 'Local migrations' "$migration_count"
pass=$((pass+1))

autonomous_docs=(
  docs/AUTONOMOUS_DEVELOPMENT.md
  docs/development/ENVIRONMENTS.md
  docs/development/TESTING.md
  docs/development/MIGRATIONS.md
  docs/development/SECURITY.md
)
for path in "${autonomous_docs[@]}"; do
  check_file "Documentation" "$path" WARN
done

if [[ -f scripts/check_repository.sh ]]; then
  if bash scripts/check_repository.sh >/tmp/schmackofatz_repository_check.log 2>&1; then
    printf 'PASS  %-28s repository hygiene\n' 'Repository check'
    pass=$((pass+1))
  else
    printf 'BLOCK %-28s see /tmp/schmackofatz_repository_check.log\n' 'Repository check'
    block=$((block+1))
  fi
else
  printf 'BLOCK %-28s scripts/check_repository.sh missing/not executable\n' 'Repository check'
  block=$((block+1))
fi

printf '\n%s\n' '--- runtime-dependent checks ---'
if command -v flutter >/dev/null 2>&1; then
  flutter --version | sed -n '1,2p'
  if flutter analyze >/tmp/schmackofatz_flutter_analyze.log 2>&1; then
    printf 'PASS  %-28s flutter analyze\n' 'Flutter analyze'
    pass=$((pass+1))
  else
    printf 'BLOCK %-28s see /tmp/schmackofatz_flutter_analyze.log\n' 'Flutter analyze'
    block=$((block+1))
  fi
else
  printf 'BLOCK %-28s Flutter runtime unavailable\n' 'Flutter analyze'
  block=$((block+1))
fi

printf '\n%s\n' '--- summary ---'
printf 'PASS=%d WARN=%d BLOCK=%d\n' "$pass" "$warn" "$block"

if (( block > 0 )); then
  printf '%s\n' 'BLOCKED: autonomous development cannot be fully verified in this environment.'
  exit 2
fi

printf '%s\n' 'READY: mandatory local readiness checks passed.'
exit 0
