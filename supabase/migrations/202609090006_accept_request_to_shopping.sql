-- v7: accepting a meal request also adds its recipe ingredients to the household list.
create or replace function public.accept_meal_request(
  p_request_id uuid,
  p_servings integer default 2
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.meal_requests%rowtype;
  plan_id uuid;
  list_id uuid;
  ingredient record;
  scaled_quantity numeric;
  base_servings integer;
begin
  select * into r from public.meal_requests
  where id = p_request_id for update;

  if r.id is null then raise exception 'meal request not found'; end if;
  if not public.is_household_member(r.household_id) then raise exception 'not a household member'; end if;
  if r.status <> 'open' then raise exception 'meal request is not open'; end if;
  if r.recipe_id is null then raise exception 'a recipe must be selected before acceptance'; end if;
  if p_servings < 1 then raise exception 'servings must be positive'; end if;

  select servings into base_servings from public.recipes where id = r.recipe_id;
  if base_servings is null or base_servings < 1 then base_servings := 1; end if;

  insert into public.meal_plans(household_id, recipe_id, planned_date, servings, created_by)
  values (r.household_id, r.recipe_id, r.requested_date, p_servings, auth.uid())
  returning id into plan_id;

  select id into list_id from public.shopping_lists
  where household_id = r.household_id limit 1;

  if list_id is null then
    insert into public.shopping_lists(household_id, name)
    values (r.household_id, 'Gemeinsamer Einkauf')
    returning id into list_id;
  end if;

  for ingredient in
    select ri.food_id, ri.quantity, ri.unit
    from public.recipe_ingredients ri
    where ri.recipe_id = r.recipe_id
  loop
    scaled_quantity := ingredient.quantity * p_servings / base_servings;

    insert into public.shopping_list_items(
      shopping_list_id, food_id, quantity, unit, name, is_checked
    )
    select list_id, ingredient.food_id, scaled_quantity, ingredient.unit, f.name, false
    from public.foods f where f.id = ingredient.food_id
    on conflict (shopping_list_id, food_id, unit)
    do update set
      quantity = coalesce(public.shopping_list_items.quantity, 0) + excluded.quantity,
      is_checked = false;
  end loop;

  update public.meal_requests set status = 'accepted' where id = r.id;
  return plan_id;
end;
$$;

grant execute on function public.accept_meal_request(uuid, integer) to authenticated;
