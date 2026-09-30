-- Collaboration + shopping list hardening.
alter table public.households
  add column if not exists invite_code text;

update public.households
set invite_code = upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8))
where invite_code is null;

alter table public.households
  alter column invite_code set not null;

create unique index if not exists households_invite_code_idx
  on public.households(invite_code);

-- One active list per household for the MVP.
create unique index if not exists shopping_lists_household_unique
  on public.shopping_lists(household_id);

-- Grants required by Supabase Data API.
grant select on public.foods to authenticated;
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.user_food_preferences to authenticated;
grant select, insert, update, delete on public.households to authenticated;
grant select, insert, update, delete on public.household_members to authenticated;
grant select, insert, update, delete on public.recipes to authenticated;
grant select, insert, update, delete on public.recipe_ingredients to authenticated;
grant select, insert, update, delete on public.meal_plans to authenticated;
grant select, insert, update, delete on public.shopping_lists to authenticated;
grant select, insert, update, delete on public.shopping_list_items to authenticated;

-- Replace overly restrictive membership insert policy with owner/join RPC flow.
drop policy if exists "own household membership insert" on public.household_members;

create or replace function public.create_household(p_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_household uuid;
begin
  insert into public.households(name, created_by, invite_code)
  values (
    trim(p_name),
    auth.uid(),
    upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8))
  )
  returning id into new_household;

  insert into public.household_members(household_id, user_id, role)
  values (new_household, auth.uid(), 'owner');

  insert into public.shopping_lists(household_id, name)
  values (new_household, 'Gemeinsame Einkaufsliste');

  return new_household;
end;
$$;

grant execute on function public.create_household(text) to authenticated;

create or replace function public.join_household(p_invite_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  household_id_out uuid;
begin
  select id into household_id_out
  from public.households
  where invite_code = upper(trim(p_invite_code));

  if household_id_out is null then
    raise exception 'Ungültiger Einladungscode';
  end if;

  insert into public.household_members(household_id, user_id, role)
  values (household_id_out, auth.uid(), 'member')
  on conflict (household_id, user_id) do nothing;

  insert into public.shopping_lists(household_id, name)
  values (household_id_out, 'Gemeinsame Einkaufsliste')
  on conflict (household_id) do nothing;

  return household_id_out;
end;
$$;

grant execute on function public.join_household(text) to authenticated;

-- Allow authenticated members to create/update shopping data only in households they belong to.
-- Existing policies already enforce membership via helper functions.

-- Realtime publication is needed for stream() / Postgres Changes.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'shopping_list_items'
  ) then
    alter publication supabase_realtime add table public.shopping_list_items;
  end if;
end $$;
