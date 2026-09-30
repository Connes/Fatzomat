#!/usr/bin/env bash
set -euo pipefail

PROJECT_REF="oidxezjdwqktpxuypbfb"
JSON_FILE="${1:-}"

if [[ -z "$JSON_FILE" ]]; then
  echo "Usage: $0 /path/to/firebase-service-account.json" >&2
  exit 2
fi
if [[ ! -f "$JSON_FILE" ]]; then
  echo "Firebase service-account file not found: $JSON_FILE" >&2
  exit 2
fi

python3 - "$JSON_FILE" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, encoding='utf-8') as f:
    data = json.load(f)
required = ('project_id', 'client_email', 'private_key')
missing = [k for k in required if not isinstance(data.get(k), str) or not data[k].strip()]
if missing:
    raise SystemExit(f"Missing required service-account fields: {', '.join(missing)}")
if data['project_id'] != 'schmackofatz-25cce':
    raise SystemExit(f"Wrong Firebase project_id: {data['project_id']}")
if '-----BEGIN PRIVATE KEY-----' not in data['private_key'] or '-----END PRIVATE KEY-----' not in data['private_key']:
    raise SystemExit('private_key does not look like a PKCS#8 PEM private key')
print('Firebase service-account JSON validated for schmackofatz-25cce.')
PY

# IMPORTANT: the secret name must be exactly FCM_SERVICE_ACCOUNT_JSON.
# Do not prefix it with "Name:" and do not paste the JSON into the name field.
supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat "$JSON_FILE")" --project-ref "$PROJECT_REF"

echo "FCM_SERVICE_ACCOUNT_JSON updated for project $PROJECT_REF."
