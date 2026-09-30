# Schmackofatz v1.12.0 – Profile/Food/Recipe Fix 2

## Hotfix: Navigator-Absturz nach „Für heute auswählen“

### Ursache
`SavedRecipesPage` ist in `AppShell` dauerhaft als Tab eines `IndexedStack` eingebunden.
Nach erfolgreicher persönlicher Rezeptauswahl wurde trotzdem `Navigator.pop(context, true)` ausgeführt.
Damit wurde versucht, den Root-Navigator zu verlassen, obwohl dort kein zugehöriger Detail-Route-Eintrag vorhanden war.
Flutter quittierte das mit der Assertion `_history.isNotEmpty`.

### Korrektur
- Kein `Navigator.pop` mehr aus `SavedRecipesPage` nach erfolgreicher Auswahl.
- Stattdessen wird der persönliche Today-Plan neu geladen und der bestehende Erfolgshinweis angezeigt.
- Navigation und Auswahlpfad bleiben unverändert.
- `RecipeDetailPage` bleibt unverändert, da sie als tatsächlich gepushte Detail-Route korrekt mit dem Navigator arbeitet.

### Regressionstest
`test/regression/today_recipe_selection_flow_test.dart` stellt sicher, dass `SavedRecipesPage` nach der persönlichen Auswahl nicht den Root-Navigator poppt.

## Bereits enthalten
- Profil-Box „Schmackofatz hilft euch …“ entfernt.
- „Meine Lebensmittel“ als begrenzte, vertikal scrollbarere Box umgesetzt.
- Supabase-RLS-Rekursion bei persönlicher Rezeptauswahl behoben.

## Verifikation
Flutter ist in der Assistenzumgebung nicht installiert; `flutter analyze` und `flutter test` konnten daher hier nicht ausgeführt werden.
Die betroffenen Quellen und der Regressionstest wurden statisch geprüft.
