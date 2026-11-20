-- Add a first-class recipe category for filtering and dessert-specific timing labels.
alter table public.recipes
  add column if not exists category text not null default '';

-- Recipes are personal records: every recipe has one owner.
-- Connections must never be required to create or edit a recipe.

create or replace function public.find_shared_recipe_duplicate(
  p_recipe jsonb,
  p_ingredients jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  fingerprint text;
  duplicate_id uuid;
begin
  if uid is null then raise exception 'Nicht authentifiziert.'; end if;
  fingerprint := public.recipe_fingerprint(p_recipe, p_ingredients);

  select r.id into duplicate_id
  from public.recipes r
  where r.created_by = uid
    and r.recipe_fingerprint = fingerprint
  order by r.created_at desc
  limit 1;

  return duplicate_id;
end;
$$;

revoke all on function public.find_shared_recipe_duplicate(jsonb,jsonb) from public, anon;
grant execute on function public.find_shared_recipe_duplicate(jsonb,jsonb) to authenticated;

create or replace function public.create_shared_recipe(
  p_recipe jsonb,
  p_ingredients jsonb,
  p_allow_duplicate boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  rid uuid;
  duplicate_id uuid;
  fingerprint text;
  item jsonb;
  ingredient_name text;
  ingredient_quantity numeric;
  ingredient_unit text;
begin
  if uid is null then raise exception 'Nicht authentifiziert.'; end if;
  if jsonb_typeof(p_recipe) <> 'object' then raise exception 'Ungültige Rezeptdaten.'; end if;
  if jsonb_typeof(p_ingredients) <> 'array' or jsonb_array_length(p_ingredients) = 0 then
    raise exception 'Ein Rezept benötigt mindestens eine Zutat.';
  end if;
  if trim(coalesce(p_recipe->>'name','')) = '' then raise exception 'Ein Rezeptname ist erforderlich.'; end if;

  fingerprint := public.recipe_fingerprint(p_recipe, p_ingredients);
  select r.id into duplicate_id
  from public.recipes r
  where r.created_by = uid
    and r.recipe_fingerprint = fingerprint
  order by r.created_at desc
  limit 1;

  if duplicate_id is not null and not coalesce(p_allow_duplicate, false) then
    return jsonb_build_object(
      'created', false,
      'recipe_id', null,
      'duplicate_recipe_id', duplicate_id
    );
  end if;

  insert into public.recipes(
    created_by, name, description, servings, servings_unit,
    prep_time_minutes, cook_time_minutes, difficulty, category, instructions,
    image_url, updated_at, recipe_fingerprint
  ) values (
    uid,
    trim(p_recipe->>'name'),
    coalesce(p_recipe->>'description',''),
    greatest(coalesce((p_recipe->>'servings')::integer,1),1),
    case when lower(coalesce(p_recipe->>'servings_unit','personen'))
      in ('stück','stueck','stücke','stuecke') then 'Stück' else 'Personen' end,
    greatest(coalesce((p_recipe->>'prep_time_minutes')::integer,0),0),
    greatest(coalesce((p_recipe->>'cook_time_minutes')::integer,0),0),
    coalesce(nullif(trim(p_recipe->>'difficulty'),''),'Einfach'),
    coalesce(nullif(trim(p_recipe->>'category'),''),''),
    coalesce(p_recipe->'instructions','[]'::jsonb),
    nullif(trim(coalesce(p_recipe->>'image_url','')),''),
    now(),
    fingerprint
  ) returning id into rid;

  for item in select value from jsonb_array_elements(p_ingredients) loop
    ingredient_name := trim(coalesce(item->>'name',''));
    ingredient_quantity := coalesce(
      nullif(item->>'quantity','')::numeric,
      nullif(item->>'amount','')::numeric,
      1
    );
    ingredient_unit := trim(coalesce(item->>'unit',''));
    if ingredient_name = '' then raise exception 'Eine Zutat benötigt einen Namen.'; end if;
    if ingredient_quantity is null or ingredient_quantity <= 0 then
      raise exception 'Zutatenmengen müssen positiv sein.';
    end if;
    if ingredient_unit = '' then raise exception 'Eine Zutat benötigt eine Einheit.'; end if;

    insert into public.recipe_ingredients(
      recipe_id, food_id, name, quantity, unit,
      is_user_selected, is_additional, is_qualitative, section
    ) values (
      rid, nullif(item->>'food_id',''), ingredient_name, ingredient_quantity, ingredient_unit,
      coalesce((item->>'is_user_selected')::boolean,false),
      coalesce((item->>'is_additional')::boolean,false),
      coalesce((item->>'is_qualitative')::boolean,false),
      nullif(trim(coalesce(item->>'section','')),'')
    );
  end loop;

  insert into public.recipe_saves(recipe_id, user_id)
  values (rid, uid)
  on conflict do nothing;

  return jsonb_build_object(
    'created', true,
    'recipe_id', rid,
    'duplicate_recipe_id', duplicate_id
  );
end;
$$;

revoke all on function public.create_shared_recipe(jsonb,jsonb,boolean) from public, anon;
grant execute on function public.create_shared_recipe(jsonb,jsonb,boolean) to authenticated;

create or replace function public.update_shared_recipe(
  p_recipe_id uuid,
  p_recipe jsonb,
  p_ingredients jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  owner_id uuid;
  fingerprint text;
  item jsonb;
  ingredient_name text;
  ingredient_quantity numeric;
  ingredient_unit text;
begin
  if uid is null then raise exception 'Nicht authentifiziert.'; end if;

  select r.created_by into owner_id
  from public.recipes r
  where r.id = p_recipe_id
  for update;

  if owner_id is distinct from uid then
    raise exception 'Du kannst nur eigene Rezepte bearbeiten.';
  end if;

  if trim(coalesce(p_recipe->>'name','')) = '' then raise exception 'Ein Rezeptname ist erforderlich.'; end if;
  if jsonb_typeof(p_ingredients) <> 'array' or jsonb_array_length(p_ingredients) = 0 then
    raise exception 'Ein Rezept benötigt mindestens eine Zutat.';
  end if;

  fingerprint := public.recipe_fingerprint(p_recipe, p_ingredients);

  if exists (
    select 1 from public.recipes r
    where r.id <> p_recipe_id
      and r.created_by = uid
      and r.recipe_fingerprint = fingerprint
  ) then
    raise exception 'Dieses Rezept gibt es bereits in deiner Rezeptsammlung.';
  end if;

  update public.recipes set
    name = trim(p_recipe->>'name'),
    description = coalesce(p_recipe->>'description',''),
    servings = greatest(coalesce((p_recipe->>'servings')::integer,1),1),
    servings_unit = case when lower(coalesce(p_recipe->>'servings_unit','personen'))
      in ('stück','stueck','stücke','stuecke') then 'Stück' else 'Personen' end,
    prep_time_minutes = greatest(coalesce((p_recipe->>'prep_time_minutes')::integer,0),0),
    cook_time_minutes = greatest(coalesce((p_recipe->>'cook_time_minutes')::integer,0),0),
    difficulty = coalesce(nullif(trim(p_recipe->>'difficulty'),''),'Einfach'),
    category = coalesce(nullif(trim(p_recipe->>'category'),''),''),
    instructions = coalesce(p_recipe->'instructions','[]'::jsonb),
    image_url = nullif(trim(coalesce(p_recipe->>'image_url','')),''),
    updated_at = now(),
    recipe_fingerprint = fingerprint
  where id = p_recipe_id and created_by = uid;

  delete from public.recipe_ingredients where recipe_id = p_recipe_id;

  for item in select value from jsonb_array_elements(p_ingredients) loop
    ingredient_name := trim(coalesce(item->>'name',''));
    ingredient_quantity := coalesce(
      nullif(item->>'quantity','')::numeric,
      nullif(item->>'amount','')::numeric,
      1
    );
    ingredient_unit := trim(coalesce(item->>'unit',''));
    if ingredient_name = '' then raise exception 'Eine Zutat benötigt einen Namen.'; end if;
    if ingredient_quantity is null or ingredient_quantity <= 0 then
      raise exception 'Zutatenmengen müssen positiv sein.';
    end if;
    if ingredient_unit = '' then raise exception 'Eine Zutat benötigt eine Einheit.'; end if;

    insert into public.recipe_ingredients(
      recipe_id, food_id, name, quantity, unit,
      is_user_selected, is_additional, is_qualitative, section
    ) values (
      p_recipe_id, nullif(item->>'food_id',''), ingredient_name, ingredient_quantity, ingredient_unit,
      coalesce((item->>'is_user_selected')::boolean,false),
      coalesce((item->>'is_additional')::boolean,false),
      coalesce((item->>'is_qualitative')::boolean,false),
      nullif(trim(coalesce(item->>'section','')),'')
    );
  end loop;

  return p_recipe_id;
end;
$$;

revoke all on function public.update_shared_recipe(uuid,jsonb,jsonb) from public, anon;
grant execute on function public.update_shared_recipe(uuid,jsonb,jsonb) to authenticated;

-- Remove broad collection reads. Recipe owners retain full access through
-- the existing "own recipes" policy; personal plan references remain readable.
drop policy if exists "recipes global library read" on public.recipes;
drop policy if exists "recipes connection collection read" on public.recipes;
drop policy if exists "recipes suggested to connection member read" on public.recipes;
drop policy if exists "recipe ingredients global library read" on public.recipe_ingredients;
drop policy if exists "recipe ingredients connection collection read" on public.recipe_ingredients;
drop policy if exists "shared recipe ingredients readable by connection" on public.recipe_ingredients;
drop policy if exists "recipe ingredients suggested read" on public.recipe_ingredients;
