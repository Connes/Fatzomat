# Release hardening v13

## Umgesetzt
- Wochen-Einkauf wird jetzt vor dem Einfügen über `(food_id, unit)` aggregiert.
- Mehrere Rezepte mit derselben Zutat erzeugen eine konsolidierte Position.
- Manuelle Einkaufsartikel bleiben beim Neuaufbau erhalten.
- `source_label` und `source_date` werden beim Wochen-Neuaufbau gesetzt.
- SQL-Smoke-Tests für zentrale Datenbank-Invarianten ergänzt.
- Flutter-Test für die Aggregationslogik ergänzt.
- GitHub Actions für `flutter analyze` und `flutter test` ergänzt.
- `.env.example` dokumentiert die öffentliche Supabase-Konfiguration und die Secret-Grenze für OpenAI.

## Bewusst nicht automatisiert
- Deployment auf ein echtes Supabase-Projekt
- App-Store-/Play-Store-Upload
- echte iOS Universal Links / Android App Links, da dafür native Projektkonfiguration und eine konkrete Domain benötigt werden

## Release-Reihenfolge
1. Migrationen in einer Test-Supabase-Instanz anwenden.
2. `supabase/tests/smoke.sql` ausführen.
3. `flutter pub get`
4. `flutter analyze`
5. `flutter test`
6. Mit zwei Testkonten denselben Haushalt öffnen.
7. Rezept annehmen und Wochen-Einkauf auf beiden Geräten prüfen.
8. Doppelte Zutaten über mehrere Rezepte prüfen.
9. Manuelle Einkaufsposition anlegen und danach Wochen-Einkauf neu aufbauen.
10. Erst danach native Deep Links und Store-Builds konfigurieren.
