# together V1.0.0

## Technische Stabilisierung

- KI-Rezeptgenerierung serverseitig gegen Missbrauch begrenzt: 5 Generierungen/Stunde und 20 Generierungen/24h pro authentifiziertem Benutzer.
- Quota-Verbrauch ist über eine PostgreSQL-Transaktion und User-Lock gegen parallele Requests abgesichert.
- Eingaben der KI-Edge-Function sind serverseitig begrenzt und validiert.
- Alle vorhandenen `SECURITY DEFINER`-Funktionen erhalten `search_path = public`; direkte Ausführung durch `public`/`anon` wird entzogen.
- Supabase-Konfiguration wird nicht mehr im Dart-Quellcode hardcodiert, sondern über `.env.local` und `--dart-define` eingebunden.
- `.env.local` und generierte Build-/IDE-Dateien sind aus der Versionskontrolle ausgeschlossen.
- Historische verschachtelte Projektkopie `v84fix/` entfernt.
- CI-Quality-Gate ergänzt: `flutter pub get`, `flutter analyze`, `flutter test`.
- Wiederholbare Release-Verifikation über `scripts/verify_release.sh` ergänzt.
- Datenbank-Smoke-Tests prüfen die neuen Security-/Quota-Artefakte.

## Release-Gate

Vor einem Release müssen erfolgreich sein:

```bash
flutter analyze
flutter test
flutter build apk --release --dart-define=SUPABASE_URL="$SUPABASE_URL" --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY"
```

Die Edge-Function benötigt `OPENAI_API_KEY` ausschließlich als Supabase Secret. Dieser Schlüssel darf niemals in Flutter, `.env.local` oder Git landen.
