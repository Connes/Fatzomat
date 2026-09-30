# Cleanup Round V46

## Product changes
- Reduced main navigation from five destinations to four: Start, Meine Rezepte, Heute, Profil.
- Shopping is now a contextual child of Heute instead of a top-level destination.
- Removed notifications from the primary product navigation and profile surface.
- Removed the duplicate ShoppingHomePage and the obsolete notification screen from the product surface.
- Centralized surprise-mode selection in `FoodDecisionService`.
- Reworked Heute status from a database-like dropdown into a visual three-step progress flow.
- Added contextual shopping progress and grouped shopping-list presentation.
- Added pull-to-refresh to Today, Shopping and Profile states.
- Recipe generation failures now offer a recovery path to the saved collection.
- Discovery screens use a clearer decision-first handoff to Maps/delivery providers.

## Technical changes
- Added typed `Recipe`, `RecipeIngredient` and `ShoppingItem` models as a migration path away from raw maps.
- Fixed saved-recipe lookup to query `recipe_saves` for the authenticated user instead of filtering all recipes by the existence of any save row.
- Added supporting indexes for recipe saves, daily plans and shopping items.
- Added unit tests for surprise selection and recipe model parsing.

## Release gates still requiring a real Supabase/Flutter environment
1. Run `flutter analyze` and `flutter test` with the project SDK.
2. Build Android release APK/AAB.
3. Run authenticated RLS tests with two isolated users.
4. Verify anonymous-account recovery/device migration strategy before production.
5. Verify OpenAI Edge Function failure behavior, quotas and cost limits.
6. Add integration tests for connection, shared recipe, Today and Realtime shopping flows.
7. If native restaurant results are required, integrate a licensed Places/provider API rather than scraping Maps.
