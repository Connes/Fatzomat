# Food App MVP v21

## Schwerpunkt: Lebensmittelkorb

v21 macht den persönlichen Lebensmittelkorb alltagstauglicher.

### Neu
- bestehende Lebensmittel-Präferenzen werden beim Öffnen geladen
- Suche nach Lebensmitteln
- Filter nach „Alle“, „Mag ich“ und „Mag ich nicht“
- Filter nach Kategorie
- Zähler für gemochte und abgelehnte Lebensmittel
- erneutes Tippen auf eine aktive Präferenz entfernt diese wieder
- verständliche Lade-/Speicherzustände
- neue reine Filterlogik mit Tests

### Unverändert
- keine sichtbare Anmeldung
- anonyme Supabase-Identität
- Haushalt, Wochenplanung und Einkaufsliste
- Rezeptgenerator
- keine Vorratsschrank-Funktion

## Lokaler Test

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```
