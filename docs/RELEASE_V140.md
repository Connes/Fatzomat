# together V1.4 Release

V1.4 schließt die Punkte 7–12 des technischen Zielzustands.

## 7. Typisierte Repository-APIs

Die öffentliche RecipeRepository-Schnittstelle arbeitet mit `Recipe` und `List<Recipe>`. Die alten Map-APIs `generateRecipes`, `saveRecipe`, `savedRecipes` und der Map-Rückgabepfad für `getRecipe` wurden entfernt. Map-Konvertierungen bleiben ausschließlich an der Datenbank-/JSON-Grenze der Models und sind damit kein Bestandteil der Feature-API.

## 8. CI Release-Gate

GitHub Actions führt zusätzlich zum Debug-Build einen Android-Release-Build aus und verwendet `flutter pub get --enforce-lockfile`.

## 9. Workflow-Duplikate

Es gibt nur noch einen Flutter-Workflow. Eine leere `ci.yml` wird durch den Repository-Check explizit verhindert.

## 10. Bootstrap

`setup.sh` generiert keine Plattformstruktur und überschreibt keine Plattformdateien. Ein unvollständiges Repository wird früh abgebrochen.

## 11. Dokumentation

Release- und technische Dokumentation liegt unter `docs/`. Das Root-Verzeichnis bleibt für Einstieg und Projektmetadaten reserviert.

## 12. Anonymous Auth / RLS

Die bestehende Anonymous-Auth-Architektur wird bewusst beibehalten. Sicherheitsgrenzen sind dokumentiert und über `authenticated`-RLS plus `auth.uid()` umgesetzt. Siehe `docs/security/ANONYMOUS_AUTH_POLICY_V140.md`.

## Cleanup-Runde

Nach dem V1.4-Hauptstand wurde die Repository-Hygiene weiter bereinigt: ein redundanter Setup-Einstieg wurde entfernt, Bootstrap greift nicht mehr in IDE- oder Plattformdateien ein, und das lokale Release-Gate prüft nun denselben Release-Build wie die CI.
