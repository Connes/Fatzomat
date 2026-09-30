-- Historical compatibility migration.
-- The former household/meal-request migration chain contains a gap at v7/006:
-- 202609090006_accept_request_to_shopping.sql depends on public.meal_requests.
-- Recreate only the minimal legacy contract required by migrations 006-009.
-- This table is intentionally retired later by
-- 202609140002_remove_household_legacy_and_normalize_food_categories.sql.

-- The legacy shopping-list chain also expects an active/archived status.
-- Later product migrations retire this table family entirely.
alter table public.shopping_lists
  add column if not exists status text not null default 'active';

alter table public.shopping_lists
  drop constraint if exists shopping_lists_status_check;

alter table public.shopping_lists
  add constraint shopping_lists_status_check
  check (status in ('active', 'archived'));

create table if not exists public.meal_requests (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  recipe_id uuid references public.recipes(id) on delete set null,
  requested_date date not null default current_date,
  status text not null default 'open'
    check (status in ('open', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz not null default now()
);

create index if not exists meal_requests_household_idx
  on public.meal_requests(household_id, requested_date, created_at desc);

create index if not exists meal_requests_recipe_idx
  on public.meal_requests(recipe_id);

alter table public.meal_requests enable row level security;

create policy "meal requests household members read"
on public.meal_requests for select to authenticated
using (public.is_household_member(household_id));

create policy "meal requests household members insert"
on public.meal_requests for insert to authenticated
with check (public.is_household_member(household_id));

create policy "meal requests household members update"
on public.meal_requests for update to authenticated
using (public.is_household_member(household_id))
with check (public.is_household_member(household_id));

create policy "meal requests household members delete"
on public.meal_requests for delete to authenticated
using (public.is_household_member(household_id));
