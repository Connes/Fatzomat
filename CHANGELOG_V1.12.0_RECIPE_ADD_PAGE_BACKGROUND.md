# V1.12.0 – Rezept hinzufügen: Hintergrund und Empty-Info

## Änderung

- `AddRecipePage` verwendet jetzt `TogetherScaffold` mit `TogetherBackgroundType.recipes`.
- Dadurch wird derselbe bestehende Rezept-Hintergrund wie bei „Meine Rezepte“ verwendet.
- Der bestehende Hinweis zum `together_recipe`-Dateiformat wurde vollständig aus dem Layout entfernt.
- Die drei vorhandenen Wege „Manuell erstellen“, „Rezeptdatei importieren“ und „Mit ChatGPT“ sowie ihre Aktionen wurden nicht verändert.

## Regressionstest

Neu: `test/regression/add_recipe_page_visual_test.dart`

Prüft:
- vorhandenen Rezept-Hintergrund
- alle drei vorhandenen Optionen
- Entfernung des Verarbeitungshinweises
- Beibehaltung der bestehenden Aktionsverdrahtung

`flutter analyze` / `flutter test` konnten in der Arbeitsumgebung nicht ausgeführt werden, da dort keine Flutter/Dart-Ausführung verfügbar ist.
