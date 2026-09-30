# Schmackofatz v1.12.0 – ChatGPT setup compile fix

## Fix
- Restored `RecipeImportPreviewPage` and its supporting section/meta widgets in `add_recipe_page.dart`.
- Preserved the existing import flow and decision-request parameters.
- A collaboration decision request is resolved without additionally writing to the personal Today plan.
- A personal Today selection is written only when `selectForToday` is true and no `decisionRequestId` is present.
- No new dependencies, assets, repository APIs, models, or database changes introduced.

## Verification
- Source-level checks completed in the patch environment.
- Flutter analyze/test should be run locally with the project’s Flutter 3.47.2 toolchain.
