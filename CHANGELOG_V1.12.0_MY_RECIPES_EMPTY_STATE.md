# Schmackofatz V1.12.0 – Meine Rezepte Empty State

## Änderung

Der bestehende Empty State von „Meine Rezepte“ wird jetzt in einer klar erkennbaren `AppSurface`-Box dargestellt. Die bestehende Rezeptlogik und der bestehende Hintergrund bleiben unverändert.

## Umsetzung

- `SavedRecipesEmptyState` als eigenständige, testbare UI-Komponente.
- Eindeutiger Key: `my_recipes_empty_state`.
- Bestehende `AppSurface` wiederverwendet: weiße Oberfläche, bestehender Divider, 22 px Radius.
- Responsive Breite mit `width: double.infinity` innerhalb bestehender 20 px Seitenabstände.
- Bestehende Texte und Empty-State-Bedingung unverändert.

## Regression

`test/regression/saved_recipes_empty_state_test.dart` prüft die sichtbare Box, ihre Designwerte, den vorhandenen Text sowie die bestehende Bedingung `recipes.isEmpty`.

## Verifizierung

Flutter/Dart ist in dieser Ausführungsumgebung nicht installiert. `flutter analyze` und `flutter test` konnten daher hier nicht ausgeführt werden und müssen auf der lokalen Flutter-3.47.2-Umgebung verifiziert werden.
