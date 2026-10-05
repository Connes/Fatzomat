#!/usr/bin/env bash
set -euo pipefail

fail=0
if grep -R --include='*.dart' -nE 'Future<List<Map<String, dynamic>>>[[:space:]]+(generateRecipes|savedRecipes)|Future<String>[[:space:]]+saveRecipe\(Map<String, dynamic>|Future<Map<String, dynamic>>[[:space:]]+getRecipe' lib >/dev/null 2>&1; then
  echo "FEHLER: Legacy-Map-APIs im RecipeRepository gefunden." >&2
  fail=1
fi

if grep -R --include='*.dart' -nE "generate-recipes|OPENAI_API_KEY|OpenAI\(" lib >/dev/null 2>&1; then
  echo "FEHLER: Der private Rezeptworkflow darf keine OpenAI-API aus Flutter aufrufen." >&2
  fail=1
fi
if [[ -f .github/workflows/ci.yml ]]; then
  echo "FEHLER: Doppelter CI-Workflow gefunden." >&2
  fail=1
fi
if [[ -f .env.local || -f .env.production || -f .env.prod ]]; then
  echo "FEHLER: Lokale/Produktions-Secrets im Arbeitsbaum gefunden." >&2
  fail=1
fi
if ! grep -q "flutter build apk --release" .github/workflows/build-apk.yml; then
  echo "FEHLER: Android-Release-Workflow enthält keinen APK-Build." >&2
  fail=1
fi
if ! grep -q "flutter pub get --enforce-lockfile" .github/workflows/flutter.yml || \
   ! grep -q "flutter pub get --enforce-lockfile" .github/workflows/build-apk.yml; then
  echo "FEHLER: CI erzwingt kein reproduzierbares Dependency-Setup in allen Flutter-Workflows." >&2
  fail=1
fi
if [[ $fail -ne 0 ]]; then exit 1; fi
echo "✓ Architektur- und Release-Härtung statisch geprüft"
