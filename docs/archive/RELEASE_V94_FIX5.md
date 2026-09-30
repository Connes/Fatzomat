# together V94 Fix5

Fixes the remaining V94 test timing issue in `v93_cook_selection_summary_test.dart`.

The test now injects a blocking fake `RecipeRepository` and advances the test clock with a bounded 500 ms pump after navigation. It deliberately does not use `pumpAndSettle()`, because `CookRecipeGenerationPage` contains an indeterminate `CircularProgressIndicator`, so the test would never become settled while the fake generation future is intentionally pending.

Production code is unchanged.
