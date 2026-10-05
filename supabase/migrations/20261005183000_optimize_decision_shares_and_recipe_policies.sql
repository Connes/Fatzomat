-- Cover the four foreign keys reported by the Supabase performance advisor.
create index if not exists decision_shares_accepted_plan_id_idx
  on public.decision_shares (accepted_plan_id)
  where accepted_plan_id is not null;

create index if not exists decision_shares_cancelled_by_idx
  on public.decision_shares (cancelled_by)
  where cancelled_by is not null;

create index if not exists decision_shares_connection_id_idx
  on public.decision_shares (connection_id);

create index if not exists decision_shares_recipe_id_idx
  on public.decision_shares (recipe_id)
  where recipe_id is not null;

-- The broad owner policy already grants the same owner predicates for
-- DELETE/INSERT/UPDATE, so these three narrower policies were redundant.
drop policy if exists "recipes own delete" on public.recipes;
drop policy if exists "recipes own insert" on public.recipes;
drop policy if exists "recipes own update" on public.recipes;
