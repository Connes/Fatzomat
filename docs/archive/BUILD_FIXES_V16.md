# v16 Build fixes

Aus dem ersten echten `flutter analyze` wurden die konkreten Fehler behoben:

- `RecipeRepository._client` → öffentlicher `client`
- fehlende `ShoppingRepository.addManualItem(...)` ergänzt
- async Callback in der Einkaufsliste korrigiert
- Flutter-Default-Widget-Test durch echten Smoke-Test ersetzt
- veraltete `DropdownButtonFormField.value`-Verwendung auf `initialValue` umgestellt
- ungenutzte Imports entfernt
- erste `BuildContext`-Async-Stelle abgesichert

Nächster lokaler Check:

```bash
flutter analyze
flutter test
flutter build apk --debug
```
