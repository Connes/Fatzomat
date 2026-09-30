# Schmackofatz v1.13.20+232

## Fix
- Zwei neu hinzugefügte Regressionstests waren versehentlich außerhalb von `main()` platziert.
- Beide Tests sind wieder Bestandteil des jeweiligen `main()`-Testkörpers.
- Release-/Regressionstests wurden auf `1.13.20+232` aktualisiert.

## Hinweis
Dieser Patch ändert keine Laufzeitlogik der App. Er behebt ausschließlich die Dart-Testsyntax, die `flutter analyze` in v1.13.19+231 verhindert hat.
