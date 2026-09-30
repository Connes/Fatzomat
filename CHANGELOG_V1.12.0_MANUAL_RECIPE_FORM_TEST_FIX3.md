# v1.12.0 – Manual Recipe Form Test Fix 3

- Fixed the remaining brittle widget assertion in `add_recipe_page_visual_test.dart`.
- The test no longer requires the `12` quantity option to be simultaneously mounted in the popup menu viewport.
- The complete quantity option list remains covered by the existing source-level regression assertion.
- No production code, recipe persistence, navigation, models, repositories, Supabase logic, dependencies, or assets were changed.
