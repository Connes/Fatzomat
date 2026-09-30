# Schmackofatz v1.12.0 – Manual Recipe Form Follow-up Fix

## Corrected after local Flutter 3.47.2 test run

- Restored the existing `RecipeImportPreviewPage` and `_SectionTitle` declarations in `add_recipe_page.dart`.
- Preserved the existing manual-recipe layout changes: responsive fields, full-width ingredient name, quantity/unit selection fields, and bottom save action.
- Corrected recipe decision handling so a collaboration decision request does **not** additionally write to the personal Today plan. A personal Today write now occurs only when `selectForToday` is true and no `decisionRequestId` is present.
- Updated the regression widget test to scroll to the ingredient section before asserting lazily built ListView content.
- Kept `DropdownButtonFormField.initialValue` for Flutter 3.47.2 compatibility without the deprecated `value` API.
- No new dependencies, assets, repository APIs, models, or navigation architecture were introduced.

## Verification

The user's local run reported:
- `flutter analyze`: passed with no issues.
- `flutter test`: 139 passed before 2 failures remained; this patch addresses both reported failures.

Flutter is not installed in the assistant runtime, so the final analyze/test run must be repeated locally.
