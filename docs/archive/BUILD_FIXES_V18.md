# v18 Build fixes

Die sieben konkreten Analyzer-Fehler aus v17 wurden erneut auf die tatsächlichen
Dateiinhalte zurückgeführt und korrigiert:

- doppelte `client`-Definition in `RecipeRepository` entfernt
- stale `_client`-Referenz in `saved_recipes_page.dart` entfernt
- `ShoppingRepository` auf genau einen `_client` reduziert
- `addManualItem(String householdId, String name)` konsistent definiert
- Aufruf der manuellen Einkaufsposition auf zwei String-Argumente korrigiert
- asynchroner `clearChecked`-Callback als Closure ausgeführt
- unnötige `_client`-Duplikate entfernt

Lokaler Test:

```bash
flutter analyze
flutter test
flutter build apk --debug
```
