# Supabase smoke tests

Run `smoke.sql` against a disposable/test Supabase database after applying all migrations.

The SQL test intentionally checks structural invariants without creating test users.
End-to-end RLS tests still need two authenticated test accounts in a real Supabase project.
