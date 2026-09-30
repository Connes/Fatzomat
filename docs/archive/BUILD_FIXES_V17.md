# v17 Build fixes

Die fünf verbleibenden Analyzer-Fehler aus v16 wurden gezielt behoben:

- `RecipeRepository` stellt einen öffentlichen `client` bereit.
- veraltete `repo._client`-Referenz in `saved_recipes_page.dart` entfernt.
- `ShoppingRepository.addManualItem(...)` wird mit Haushalt + Name aufgerufen.
- `ShoppingRepository` besitzt wieder einen gültigen Supabase-Client.
- asynchroner Einkaufslisten-Callback wurde als Closure übergeben.

Bitte im lokalen Projekt ausführen:

```bash
flutter analyze
flutter test
flutter build apk --debug
```
