# Migration Drift Reconciliation

## Status

22.09.2026

The repository contains 63 SQL migrations after the security-hardening migration added during this review. The live Supabase migration history currently contains 41 entries, including the security-definer search_path hardening migration applied on 2026-09-22.

The difference is not a single missing tail migration. The repository contains an earlier product-generation history beginning with the former household/weekly-planning schema. Later migrations explicitly remove that legacy model. The live migration history starts after that historical transition and therefore cannot be treated as a byte-for-byte replay of the repository history.

## Evidence

- Local migration files include `202609090001_initial.sql` through the subsequent household/weekly-planning migrations.
- `202609140002_remove_household_legacy_and_normalize_food_categories.sql` explicitly removes the former household/meal-plan/shopping-list model.
- Live migration history begins with `20260914171458 remove_household_legacy_and_normalize_food_categories` and contains later production migrations through `20260922201831 security_definer_search_path_hardening`.
- Live schema currently contains the personal-first model (`personal_today_plans`, `personal_decision_history`, personal shopping ownership) and does not contain the retired household tables.

## Decision

Already executed historical migrations are not rewritten or deleted. Doing so would make the repository less auditable and could invalidate environments that retain the old migration history.

Instead, the project now treats the current schema contract as an explicit verification target. `supabase/tests/smoke.sql` validates critical final-state invariants, and new forward migrations remain the only mechanism for future production changes.

## Remaining limitation

A complete fresh-database replay of all 63 local migrations could not be executed in this environment because the Supabase CLI/local PostgreSQL runtime is unavailable. Creating a temporary Supabase branch would require a separately confirmed billable branch and was therefore not performed automatically.

Consequently, migration reproducibility is **not fully verified**. The historical drift is documented rather than falsely declared solved.

## Required next verification

Run the complete local migration chain against a disposable PostgreSQL/Supabase database and execute `supabase/tests/smoke.sql`. Compare the resulting catalog against the live schema before declaring migration drift closed.
