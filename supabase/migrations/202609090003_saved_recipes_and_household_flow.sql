-- Saved recipe access inside a household.
-- Recipes remain owned by their creator, but household members may read
-- recipes that are explicitly added to a household meal plan.

drop policy if exists "own recipes" on public.recipes;
create policy "own or household recipes"
on public.recipes for select to authenticated
using (
  created_by = auth.uid()
  or exists (
    select 1
    from public.meal_plans mp
    where mp.recipe_id = recipes.id
      and public.is_household_member(mp.household_id)
  )
);

create policy "create own recipes"
on public.recipes for insert to authenticated
with check (created_by = auth.uid());

create policy "update own recipes"
on public.recipes for update to authenticated
using (created_by = auth.uid())
with check (created_by = auth.uid());

create policy "delete own recipes"
on public.recipes for delete to authenticated
using (created_by = auth.uid());

drop policy if exists "recipe ingredients via own recipe" on public.recipe_ingredients;
create policy "recipe ingredients readable to permitted recipe"
on public.recipe_ingredients for select to authenticated
using (
  exists (
    select 1 from public.recipes r
    where r.id = recipe_id
      and (
        r.created_by = auth.uid()
        or exists (
          select 1 from public.meal_plans mp
          where mp.recipe_id = r.id
            and public.is_household_member(mp.household_id)
        )
      )
  )
);

create policy "recipe ingredients insert own recipe"
on public.recipe_ingredients for insert to authenticated
with check (
  exists (
    select 1 from public.recipes r
    where r.id = recipe_id and r.created_by = auth.uid()
  )
);

create policy "recipe ingredients update own recipe"
on public.recipe_ingredients for update to authenticated
using (
  exists (
    select 1 from public.recipes r
    where r.id = recipe_id and r.created_by = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.recipes r
    where r.id = recipe_id and r.created_by = auth.uid()
  )
);

create policy "recipe ingredients delete own recipe"
on public.recipe_ingredients for delete to authenticated
using (
  exists (
    select 1 from public.recipes r
    where r.id = recipe_id and r.created_by = auth.uid()
  )
);

-- Create a meal-plan entry and return its id.
create or replace function public.add_recipe_to_household(
  p_household_id uuid,
  p_recipe_id uuid,
  p_planned_date date,
  p_servings integer
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
begin
  if not public.is_household_member(p_household_id) then
    raise exception 'Kein Zugriff auf diesen Haushalt';
  end if;

  if not exists (
    select 1 from public.recipes
    where id = p_recipe_id
      and (
        created_by = auth.uid()
        or exists (
          select 1 from public.meal_plans mp
          where mp.recipe_id = p_recipe_id
            and public.is_household_member(mp.household_id)
        )
      )
  ) then
    raise exception 'Rezept nicht verfügbar';
  end if;

  insert into public.meal_plans(
    household_id, recipe_id, created_by, planned_date, servings
  )
  values (
    p_household_id, p_recipe_id, auth.uid(), p_planned_date, p_servings
  )
  returning id into new_id;

  return new_id;
end;
$$;

grant execute on function public.add_recipe_to_household(uuid, uuid, date, integer)
to authenticated;

-- Add a recipe's ingredients to the household shopping list and merge
-- matching food_id + unit items.
create or replace function public.add_recipe_to_shopping_list(
  p_household_id uuid,
  p_recipe_id uuid,
  p_servings integer
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  list_id uuid;
  base_servings integer;
  ingredient record;
  factor numeric;
  amount numeric;
  merged_count integer := 0;
  existing_id uuid;
begin
  if not public.is_household_member(p_household_id) then
    raise exception 'Kein Zugriff auf diesen Haushalt';
  end if;

  select id into list_id
  from public.shopping_lists
  where household_id = p_household_id;

  if list_id is null then
    insert into public.shopping_lists(household_id)
    values (p_household_id)
    returning id into list_id;
  end if;

  select servings into base_servings
  from public.recipes
  where id = p_recipe_id;

  if base_servings is null then
    raise exception 'Rezept nicht gefunden';
  end if;

  if p_servings <= 0 then
    raise exception 'Ungültige Personenanzahl';
  end if;

  factor := p_servings::numeric / base_servings::numeric;

  for ingredient in
    select * from public.recipe_ingredients
    where recipe_id = p_recipe_id
  loop
    amount := ingredient.quantity * factor;
    existing_id := null;

    if ingredient.food_id is not null then
      select id into existing_id
      from public.shopping_list_items
      where shopping_list_id = list_id
        and food_id = ingredient.food_id
        and unit = ingredient.unit
      limit 1;
    end if;

    if existing_id is not null then
      update public.shopping_list_items
      set quantity = quantity + amount,
          updated_at = now()
      where id = existing_id;
    else
      insert into public.shopping_list_items(
        shopping_list_id, food_id, name, quantity, unit,
        created_by, source_recipe_id
      )
      values (
        list_id, ingredient.food_id, ingredient.name, amount,
        ingredient.unit, auth.uid(), p_recipe_id
      );
    end if;

    merged_count := merged_count + 1;
  end loop;

  update public.shopping_lists
  set updated_at = now()
  where id = list_id;

  return merged_count;
end;
$$;

grant execute on function public.add_recipe_to_shopping_list(uuid, uuid, integer)
to authenticated;
