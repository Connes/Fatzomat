-- v8: household votes on meal requests.
create table if not exists public.meal_request_votes (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.meal_requests(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  vote smallint not null check (vote in (-1, 1)),
  created_at timestamptz not null default now(),
  unique(request_id, user_id)
);

create index if not exists meal_request_votes_request_idx
  on public.meal_request_votes(request_id);

alter table public.meal_request_votes enable row level security;

create policy "meal request votes household read"
on public.meal_request_votes for select to authenticated
using (
  exists (
    select 1 from public.meal_requests r
    where r.id = request_id
      and public.is_household_member(r.household_id)
  )
);

create policy "meal request votes member insert"
on public.meal_request_votes for insert to authenticated
with check (
  user_id = auth.uid()
  and exists (
    select 1 from public.meal_requests r
    where r.id = request_id
      and public.is_household_member(r.household_id)
  )
);

create policy "meal request votes own update"
on public.meal_request_votes for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "meal request votes own delete"
on public.meal_request_votes for delete to authenticated
using (user_id = auth.uid());

alter table public.meal_request_votes replica identity full;
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'meal_request_votes'
  ) then
    alter publication supabase_realtime add table public.meal_request_votes;
  end if;
end $$;

-- Consolidate all confirmed meal-plan ingredients for a household.
create or replace function public.rebuild_household_shopping_list(
  p_household_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  list_id uuid;
  inserted_count integer := 0;
  plan record;
  ingredient record;
  scaled numeric;
begin
  if not public.is_household_member(p_household_id) then
    raise exception 'not a household member';
  end if;

  select id into list_id
  from public.shopping_lists
  where household_id = p_household_id
  limit 1;

  if list_id is null then
    insert into public.shopping_lists(household_id, name)
    values (p_household_id, 'Gemeinsamer Einkauf')
    returning id into list_id;
  end if;

  -- Only remove automatically generated recipe items. Manual items remain.
  delete from public.shopping_list_items sli
  where sli.shopping_list_id = list_id
    and sli.recipe_source_plan_id is not null;

  for plan in
    select mp.id, mp.recipe_id, mp.servings, r.servings as base_servings
    from public.meal_plans mp
    join public.recipes r on r.id = mp.recipe_id
    where mp.household_id = p_household_id
      and mp.planned_date >= current_date
      and mp.planned_date < current_date + 8
  loop
    for ingredient in
      select food_id, quantity, unit
      from public.recipe_ingredients
      where recipe_id = plan.recipe_id
    loop
      scaled := ingredient.quantity * plan.servings /
        greatest(plan.base_servings, 1);

      insert into public.shopping_list_items(
        shopping_list_id, food_id, quantity, unit, name, is_checked, recipe_source_plan_id
      )
      select
        list_id, ingredient.food_id, scaled, ingredient.unit, f.name, false, plan.id
      from public.foods f
      where f.id = ingredient.food_id
      on conflict do nothing;

      inserted_count := inserted_count + 1;
    end loop;
  end loop;

  return inserted_count;
end;
$$;

grant execute on function public.rebuild_household_shopping_list(uuid) to authenticated;

alter table public.shopping_list_items
  add column if not exists recipe_source_plan_id uuid
  references public.meal_plans(id) on delete set null;

create index if not exists shopping_list_items_recipe_source_idx
  on public.shopping_list_items(recipe_source_plan_id);
