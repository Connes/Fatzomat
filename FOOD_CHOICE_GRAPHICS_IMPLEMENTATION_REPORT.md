# Fatzomat – Food-Choice-Grafiken Integration

## Status

| Punkt | Status |
|---|---|
| Neue Delivery-Grafiken übernommen | PASS |
| Alle 8 Order-Auswahlgrafiken unter `delivery/` | PASS |
| Alte `order/*.webp` entfernt | PASS |
| Zentrale Asset-Zuordnung | PASS |
| `pubspec.yaml` | PASS |
| Auswahlkarten auf dedizierte Assets umgestellt | PASS |
| Regressionstests für Order-Assets | PASS |
| `flutter analyze` | NOT VERIFIED |
| `flutter test` | NOT VERIFIED |

Die acht neuen Delivery-Grafiken liegen als PNG mit 1024×448 px unter
`assets/food_choices/delivery/`.

## Zentrale Zuordnung

Die Zuordnung liegt in `lib/core/services/food_choice_asset_service.dart`.
Der Order-Modus verwendet für alle acht Auswahlmöglichkeiten ausschließlich die
neuen Delivery-PNGs. Die beiden alten Order-WebPs werden nicht mehr referenziert.

## Regressionstests

`test/regression/food_choice_asset_service_test.dart` prüft die vollständige
Zuordnung aller acht Order-Auswahlwerte zu den erwarteten Delivery-Pfaden.

`test/regression/food_choice_assets_test.dart` prüft weiterhin, dass alle über
`FoodChoiceAssetService` referenzierten Assets tatsächlich vorhanden sind.

## Unverändert

Die bestehenden Cooking-, Restaurant- und Surprise-Assets sowie die fachlichen
Flows bleiben unverändert.

## Lokale Abschlussprüfung

```bash
flutter pub get
flutter analyze
flutter test
```

Erwartung: keine neuen Analyze-Fehler und alle Regressionstests grün.
