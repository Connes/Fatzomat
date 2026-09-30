# together Food App – V94 Fix3

## Korrektur
Der Test `V94 trennt neue und gespeicherte Rezeptsuche` wartet nicht mehr mit `pumpAndSettle()` auf die neue Rezeptsuche.

`CookRecipeGenerationPage` startet beim Öffnen absichtlich einen asynchronen Rezept-Request. `pumpAndSettle()` wartet deshalb auch auf diesen Request und kann die Seite bereits durch die anschließende Navigation zu `RecipeResultsPage` ersetzt vorfinden. Der Test wartet stattdessen gezielt 500 ms auf die Route-Animation und prüft dann die geöffnete Generation-Seite.

Keine Produktionslogik geändert.
