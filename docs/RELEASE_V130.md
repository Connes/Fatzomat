# together V1.3 Release

V1.3 schließt die noch offenen technischen Punkte aus dem V1.2-Audit mit Schwerpunkt auf Datenbank-Sicherheit, reproduzierbaren Releases, typisierten Datenzugriffen und ehrlichem Offline-Verhalten.

## Vor Release

1. `cp .env.example .env.local` und lokale Supabase-Publishable-Credentials eintragen.
2. Vollständiges Repository inklusive `android/`, `ios/` und `pubspec.lock` verwenden.
3. `flutter pub get` ausführen.
4. Supabase Auth: Leaked Password Protection aktivieren, falls Passwort-Login angeboten wird.
5. `./scripts/verify_release.sh` ausführen.

Die Supabase-Migration `20260917193000_v130_security_hardening` und Edge Function `generate-recipes` V8 sind bereits auf dem Projekt ausgerollt.
