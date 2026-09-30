# Heute-Seite: Statusleisten-Safe-Area

## Änderung

Die Heute-Seite berücksichtigt den tatsächlichen oberen `viewPadding` des Geräts, damit die System-Statusleiste nicht mehr über dem Hintergrundbild liegt.

- Das vorhandene Schmackofatz-Hintergrundbild bleibt unverändert.
- Für die Heute-Seite beginnt die Hintergrundgrafik erst unterhalb der realen oberen Safe Area.
- Der Statusleistenbereich verwendet die bestehende helle Schmackofatz-Hintergrundfarbe.
- Die Statusleisten-Icons werden auf dunkle Darstellung gesetzt.
- Die bestehende System-UI anderer Screens bleibt unverändert.
- Keine Änderung an TodayPlan, Connection, Supabase, RLS oder RPCs.

## Tests

Neu: `test/regression/today_status_bar_safe_area_test.dart`

Flutter/Dart waren in der Ausführungsumgebung nicht verfügbar. Daher sind `flutter analyze` und `flutter test` lokal zu verifizieren.


### Regression-test follow-up
- Corrected Food Mode visual tests to ignore the background image when asserting choice assets.
- Corrected dine-out visibility assertions for Flutter's lazy `GridView` child construction.
- No production UI/business logic changed.


### Regression-test follow-up 2
- Dine-out-Test auf `scrollUntilVisible()` umgestellt, damit lazy erzeugte Grid-Elemente zuverlässig gefunden werden.
- `setup.sh` im Paket wieder ausführbar markiert.
- Keine Produktionslogik geändert.

## Test-Harness Follow-up 3

- The previous `scrollUntilVisible()` approach still failed for lazy `GridView` children because a target label that had not yet been built cannot be resolved by `scrollUntilVisible()`.
- The dine-out regression test now scrolls the actual `GridView` by gesture while checking whether each label has entered the widget tree.
- The test then scrolls back to the first row before checking the Italian image asset.
- Production code remains unchanged.
