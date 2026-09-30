-- Meal planning and household collaboration refinements.

create index if not exists meal_plans_household_date_idx
  on public.meal_plans(household_id, planned_date, created_at);

-- A member can read all meal plans in their household.
drop policy if exists "meal plans household members" on public.meal_plans;
create policy "meal plans household members"
on public.meal_plans for select to authenticated
using (public.is_household_member(household_id));

create policy "meal plans insert household members"
on public.meal_plans for insert to authenticated
with check (
  public.is_household_member(household_id)
  and created_by = auth.uid()
);

create policy "meal plans update creator"
on public.meal_plans for update to authenticated
using (created_by = auth.uid())
with check (created_by = auth.uid());

create policy "meal plans delete creator"
on public.meal_plans for delete to authenticated
using (created_by = auth.uid());

-- Realtime for meal plans.
alter table public.meal_plans replica identity full;
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'meal_plans'
  ) then
    alter publication supabase_realtime add table public.meal_plans;
  end if;
end $$;

-- Return the first household for the signed-in user.
create or replace function public.get_primary_household()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select household_id
  from public.household_members
  where user_id = auth.uid()
  order by created_at
  limit 1;
$$;

grant execute on function public.get_primary_household() to authenticated;
