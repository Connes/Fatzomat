-- v9: source metadata for shopping items and a secure invite lookup.
alter table public.shopping_list_items
  add column if not exists source_label text;

create index if not exists meal_plans_household_date_idx_v9
  on public.meal_plans(household_id, planned_date);

create or replace function public.household_by_invite_code(p_invite_code text)
returns table(id uuid, name text)
language sql
stable
security definer
set search_path = public
as $$
  select h.id, h.name
  from public.households h
  where upper(h.invite_code) = upper(trim(p_invite_code))
  limit 1;
$$;

grant execute on function public.household_by_invite_code(text) to authenticated;
