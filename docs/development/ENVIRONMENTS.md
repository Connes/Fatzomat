# Entwicklungsumgebungen

## Local

Wegwerfbar und reproduzierbar. Für Flutter, lokale Supabase-Datenbank, Migrationen und schnelle Tests.

## Test

Automatisierte Tests mit deterministischen Testdaten. Keine Produktionsdaten.

## Staging

Separates Supabase-Projekt oder isolierte Preview-Umgebung mit eigenen Auth-Daten, Secrets und Edge Functions.

## Production

Nur kontrollierte Releases. Autonome Prozesse dürfen Production nicht ohne explizite menschliche Freigabe verändern.

## Credentials

Jede Umgebung verwendet eigene Credentials. Service-Role-/Secret-Keys gehören niemals in Flutter, Git oder Testartefakte.
