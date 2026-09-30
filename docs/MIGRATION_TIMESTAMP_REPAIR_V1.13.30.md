# Migration Timestamp Repair

The three migrations that previously shared `20260927193000` now have unique timestamps:

- `20260927193001_decision_share_once_per_day.sql`
- `20260927193002_shared_shopping_on_decision_accept.sql`
- `20260927193003_shared_today_decision_sync_delete.sql`

The source tree does not contain a live Supabase migration-history table, so whether an external/deployed database has already recorded the old filenames could not be verified in this environment.

If these migrations have already been applied to a deployed Supabase project, do **not** blindly push the renamed files. First reconcile the remote migration history with the source tree using the Supabase CLI migration repair workflow, then verify with `supabase migration list` and a fresh database reset.
