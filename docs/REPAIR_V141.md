# V1.4.1 Repair

Reparatur nach der lokalen Flutter-Validierung von V1.4.

Behoben:
- typisierte Food-Verwendung in AdditionalIngredientsPage
- typisierte RecipeIngredient-Verwendung in RecipeDetailPage
- versehentlich in ShoppingPage/Dialog geratene TodayController-/NetworkStatus-Logik entfernt
- doppeltes Dispose in TodayPage entfernt
- Regressionstest-Helfer `recipeMatchesSelection` wiederhergestellt
- generierten Flutter-Default-Test `widget_test.dart` entfernt, da die Anwendung keinen `MyApp`-Entry besitzt
- Version auf 1.4.1+141 angehoben

Hinweis: Android-/iOS-Plattformdateien müssen aus der lokalen Flutter-Umgebung übernommen werden.
