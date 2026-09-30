# Beta Release Checklist v12

## Umgesetzt
- verständlichere zentrale Fehlertexte
- normalisierte manuelle Einkaufsartikel
- klarer Empty State im Einkauf
- Datenbank-Constraint gegen nicht-positive Einkaufsmengen
- Unique Index für genau eine aktive Einkaufsliste pro Haushalt
- sichere RPC `get_or_create_active_shopping_list`

## Vor TestFlight / Play Internal Testing
1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. Supabase-Migrationen in einer Testinstanz anwenden
5. RLS mit mindestens zwei Haushaltsmitgliedern testen
6. Realtime mit zwei Geräten testen
7. Einladungscode auf zwei Accounts testen
8. Rezeptannahme → Wochenplan → Einkauf auf zwei Geräten testen
9. Abmelden/erneut anmelden testen
10. Fehlerfälle ohne Internet testen

## Noch offen
- echte iOS Universal Links / Android App Links
- Push Notifications
- Produktions-CI/CD
- App-Store-/Play-Store-Metadaten
- Analytics/Crash Reporting
- Offline-Synchronisation mit Konfliktauflösung
