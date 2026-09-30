# Schmackofatz v1.13.4+216

- Fixed the startup error shown after completing “Kurz einrichten”.
- Saved recipe loading no longer requires `recipes.updated_at`, which is not yet present in the currently deployed Supabase schema.
- Recipe collection ordering now uses the already deployed `created_at` column.
- Added a regression test for schema compatibility.

Root cause: the AppShell initializes the saved-recipes tab while opening Today. That tab queried `recipes.updated_at`; the production database currently stops before the migration that adds that column.
