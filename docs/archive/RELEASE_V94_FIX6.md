# together V94 Fix6

Fixes the remaining V94 test timing issue in `v93_cook_selection_summary_test.dart`.

The test previously called `pumpAndSettle()` after injecting a deliberately blocking recipe repository. That can never settle because `CookRecipeGenerationPage` intentionally remains in its loading state. The test now performs bounded pumps before tapping the navigation action, then verifies the generation page after the route transition.

No production application code was changed.
