-- v13: deterministic weekly shopping rebuild.
-- Replaces the previous row-by-row conflict behavior, which could fail to aggregate
-- identical ingredients coming from different meal plans.
create or replace function public.rebuild_household_shopping_list(p_household_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_list_id uuid;
begin
  if not public.is_household_member(p_household_id) then
    raise exception 'not a household member';
  end if;

  v_list_id := public.get_or_create_active_shopping_list(p_household_id);

  -- Only remove automatically generated recipe items. Manual items survive.
  delete from public.shopping_list_items
  where shopping_list_id = v_list_id
    and recipe_source_plan_id is not null;

  insert into public.shopping_list_items
    (shopping_list_id, food_id, quantity, unit, checked, recipe_source_plan_id,
     source_label, source_date)
  select
    v_list_id,
    x.food_id,
    sum(x.quantity) as quantity,
    x.unit,
    false,
    null,
    case
      when count(distinct x.recipe_name) = 1 then max(x.recipe_name)
      else count(distinct x.recipe_name)::text || ' Rezepte'
    end,
    min(x.plan_date)
  from (
    select
      mp.id as plan_id,
      mp.plan_date,
      coalesce(r.title, 'Rezept') as recipe_name,
      ri.food_id,
      ri.quantity * mp.servings::numeric / nullif(r.servings, 0) as quantity,
      ri.unit
    from public.meal_plans mp
    join public.recipes r on r.id = mp.recipe_id
    join public.recipe_ingredients ri on ri.recipe_id = r.id
    where mp.household_id = p_household_id
      and mp.plan_date >= current_date
      and mp.plan_date < current_date + 7
  ) x
  group by x.food_id, x.unit
  having sum(x.quantity) > 0;

  return v_list_id;
end;
$$;

grant execute on function public.rebuild_household_shopping_list(uuid) to authenticated;
