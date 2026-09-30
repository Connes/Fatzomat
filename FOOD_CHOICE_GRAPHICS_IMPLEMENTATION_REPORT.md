# Schmackofatz – Food-Choice-Grafiken Integration

## Status

| Punkt | Status |
|---|---|
| Asset-Struktur | PASS |
| 18 Auswahlgrafiken übernommen | PASS |
| Zentrale Asset-Zuordnung | PASS |
| `pubspec.yaml` | PASS |
| Bestehende Referenzgrafiken unverändert | PASS |
| Auswahlkarten auf neue Assets umgestellt | PASS |
| Fachlogik / Today / Connection / Discovery unverändert | PASS |
| Regressionstests angepasst/ergänzt | PASS |
| `flutter analyze` | NOT VERIFIED |
| `flutter test` | NOT VERIFIED |

`flutter` und `dart` waren in der Ausführungsumgebung nicht installiert. Deshalb wurden Analyse und Flutter-Testlauf nicht als erfolgreich behauptet.

## Asset-Struktur

```text
assets/food_choices/
  cooking/
    rind.png
    schwein.png
    huhn.png
    fisch.png
    vegetarisch.png
  delivery/
    pizza.png
    burger.png
    asiatisch.png
    doener.png
    sushi.png
    indisch.png
  restaurant/
    italienisch.png
    steak.png
    asiatisch.png
    sushi.png
    burger.png
    mexikanisch.png
    vegetarisch.png
```

Alle 18 neuen PNGs sind 540×480 px.

## Zentrale Zuordnung

Die Zuordnung liegt in:

`lib/core/services/food_choice_asset_service.dart`

Sie trennt Cooking, Delivery und Restaurant bewusst. Das ist wichtig bei identischen Auswahlwerten wie `Burger`, `Asiatisch`, `Sushi` und `Vegetarisch`, damit nicht versehentlich das Asset eines anderen Modus angezeigt wird.

## Geänderte Flutter-Dateien

- `lib/features/food_modes/food_mode_page.dart`
  - Icons der Auswahlkarten durch die dedizierten Assets ersetzt.
  - bestehende `_OptionCard` wiederverwendet.
  - Auswahlwerte und bestehende Navigation/Entscheidungslogik unverändert.
  - `Semantics`-Labels bleiben erhalten.
- `lib/core/services/food_choice_asset_service.dart`
  - zentrale Asset-Zuordnung.

## Weitere Änderungen

- `pubspec.yaml`
  - `assets/food_choices/` registriert.
- `test/regression/food_mode_selection_visual_test.dart`
  - prüft Asset-Zuordnung und Darstellung.
- `test/regression/food_choice_assets_test.dart`
  - prüft, dass alle erwarteten Assets vorhanden sind.
- `test/regression/cook_next_step_test.dart`
  - Auswahl wird jetzt über das bestehende Accessibility-Semantics-Label statt über das entfernte Icon angesprochen.
- `CHANGELOG_V1.12.0_RESTAURANT_DISCOVERY.md`
  - Integration dokumentiert.

## Unverändert

Die vier bestehenden Referenzgrafiken bleiben unverändert:

- `icon_cooking.png`
- `icon_delivery.png`
- `icon_restaurant.png`
- `icon_surprise.png`

Es wurden keine Supabase-, RLS-, RPC-, TodayPlan-, Connection-, Restaurant-Discovery- oder Delivery-Discovery-Änderungen vorgenommen.

## Lokale Abschlussprüfung

Im Projektverzeichnis ausführen:

```bash
flutter pub get
flutter analyze
flutter test
```

Erwartung: keine neuen Analyze-Fehler und alle Regressionstests grün.

## Selbst-Audit

- Neue Grafiken tatsächlich in `FoodModePage` eingebunden: PASS
- Keine alte Auswahl-Iconlogik mehr in `_OptionCard`: PASS
- Cooking / Delivery / Restaurant getrennt: PASS
- Alle 18 aktuellen Auswahlmöglichkeiten abgedeckt: PASS
- Überrasch mich bleibt die bestehende Referenzgrafik: PASS
- Auswahltexte bleiben Flutter-UI und werden nicht in den neuen Bildern benötigt: PASS
- Bestehende fachliche Flows unangetastet: PASS
- Runtime-Test mit Flutter: NOT VERIFIED
