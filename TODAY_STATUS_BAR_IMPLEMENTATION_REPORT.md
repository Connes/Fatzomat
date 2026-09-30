# Schmackofatz – Heute Statusleiste

## Ziel

Die System-Statusleiste auf der Heute-Seite soll nicht mehr über dem vorhandenen Hintergrundbild liegen. Uhrzeit, Benachrichtigungen, Netzwerk- und Akkuanzeigen sollen klar lesbar bleiben.

## Umsetzung

- `TogetherBackground` unterstützt optional `respectTopSafeArea`.
- Bei aktivierter Option wird `MediaQuery.viewPaddingOf(context).top` verwendet.
- Das Hintergrundbild wird erst unterhalb dieses realen Insets positioniert.
- Der ausgesparte Statusleistenbereich erhält die bestehende `AppDesign.background`-Farbe über das Scaffold-Theme.
- `TodayPage` aktiviert diese Option ausschließlich für die Heute-Seite.
- `TodayPage` setzt für die Statusleiste transparente Farbe, dunkle Icons und die passende iOS-Helligkeit.
- Andere Screens behalten ihr bisheriges Background-Verhalten.

## Geänderte Dateien

- `lib/core/widgets/together_background.dart`
- `lib/core/widgets/together_scaffold.dart`
- `lib/features/shared/today_page.dart`
- `test/regression/today_home_ux_test.dart`
- `test/regression/today_status_bar_safe_area_test.dart`
- `CHANGELOG_V1.12.0_TODAY_STATUS_BAR.md`

## Fachlogik

Keine Änderungen an:

- TodayPlan
- persönlichen Entscheidungen
- Connection
- Supabase
- RLS
- RPCs
- Restaurant Discovery
- Delivery Discovery
- Navigation

## Status

- Safe-Area-Implementierung: PASS
- Keine festen Pixelwerte für die Statusleistenhöhe: PASS
- Bestehendes Hintergrundbild weiterverwendet: PASS
- Statusleisten-Icons auf Today kontrastreich konfiguriert: PASS
- Andere Screens nicht auf Safe-Area-Verhalten umgestellt: PASS
- `flutter analyze`: lokal durch den Nutzer verifiziert: PASS
- `flutter test`: lokal bis 131 Tests gelaufen; 1 Regressionstestfehler bleibt vor dem aktuellen Test-Harness-Fix

Flutter/Dart waren in der Arbeitsumgebung nicht installiert.


## Local verification follow-up

The user ran the fixed package with Flutter 3.47.2. `flutter analyze` passed with `No issues found!`. The full test suite reached 129 tests with 3 failures, all in `test/regression/food_mode_selection_visual_test.dart`.

The failures were test-harness assumptions, not production UI failures:
- the tests selected the first `Image`, which was the page background (`recipes_background.png`) rather than the food-choice image;
- the dine-out test assumed all grid labels were simultaneously built, but the `GridView` lazily builds off-screen children.

The regression test was corrected to identify the expected `AssetImage` by asset path and to scroll/ensure visibility before asserting lazy grid labels. No production decision logic was changed.

Current verification status after this correction: `flutter analyze` was verified by the user before the test-only correction; `flutter test` should be rerun locally after installing this package.

## Local verification follow-up 2

Der Nutzerlauf mit Flutter 3.47.2 erreichte 131 Tests; nur `Wir gehen essen zeigt Grafiken und Auswahltexte` schlug fehl. Ursache war, dass `tester.ensureVisible()` einen noch nicht gebauten, außerhalb des sichtbaren Bereichs liegenden `GridView`-Eintrag direkt über einen leeren Finder ansprechen kann.

Der Test wurde erneut angepasst: Für die Dine-out-Labels verwendet er jetzt `tester.scrollUntilVisible(...)` auf der `Scrollable`, sodass die lazy erzeugten Grid-Kinder zunächst gebaut werden. Die Produktionsdateien und die Food-Choice-Logik bleiben unverändert. `setup.sh` ist im Paket außerdem wieder als ausführbar markiert.

`flutter test` nach diesem letzten Test-Harness-Fix konnte in der Arbeitsumgebung nicht selbst ausgeführt werden, da dort Flutter/Dart nicht installiert ist.

## Local Test-Harness Follow-up 3

A second local test run showed one remaining failure in `food_mode_selection_visual_test.dart`. The failure was caused by `scrollUntilVisible()` being unsuitable for a lazy `GridView` when the requested text widget has not yet been built. The regression test was changed to drag the concrete `GridView` until each label exists, then return to the first row before checking the Italian asset. No production implementation was changed.
