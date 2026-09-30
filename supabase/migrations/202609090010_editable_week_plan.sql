-- v11: shopping source metadata and editable meal plan details.
alter table public.shopping_list_items
  add column if not exists source_date date;

create index if not exists shopping_items_source_date_idx
  on public.shopping_list_items(source_date);

create or replace function public.update_meal_plan_servings(
  p_plan_id uuid,
  p_servings integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_servings < 1 then
    raise exception 'servings must be positive';
  end if;

  update public.meal_plans mp
  set servings = p_servings
  where mp.id = p_plan_id
    and public.is_household_member(mp.household_id);

  if not found then
    raise exception 'meal plan not found or not a household member';
  end if;
end;
$$;

grant execute on function public.update_meal_plan_servings(uuid, integer) to authenticated;
