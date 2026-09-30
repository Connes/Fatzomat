# Test-Fix Abschluss

## Befund
`flutter analyze` war bereits grün. Die drei Fehlschläge waren Test-Harness-Probleme, keine Fehler der Restaurant-Discovery-Implementierung:

1. `Anbieter 9` lag in einer lazy aufgebauten `ListView` außerhalb des initial sichtbaren Bereichs. `find.text()` konnte ihn daher ohne Scrollen nicht finden.
2. Dasselbe galt für `Anbieter 9` im zweiten Test.
3. `RestaurantDetailPage` zeigt den Restaurantnamen absichtlich zweimal: einmal in der App-Bar und einmal im Detail-Header. Der Test erwartete fälschlich genau ein Vorkommen.

## Korrektur
- Die beiden Discovery-Tests scrollen vor der Prüfung von `Anbieter 9` gezielt zum Eintrag.
- Der Detailtest erwartet die zwei absichtlichen Namensvorkommen.
- Produktionscode wurde nicht verändert, weil die beobachteten Fehler ausschließlich aus den Testannahmen entstanden.

## Verifikation
Die Korrekturen wurden statisch gegen die betroffenen Testdateien geprüft. Flutter/Dart ist in der aktuellen Ausführungsumgebung nicht installiert, daher konnte hier kein erneuter `flutter test` ausgeführt werden. Der übermittelte Lauf zeigt jedoch bereits `flutter analyze: No issues found!`.
