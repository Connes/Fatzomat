-- Recipe integrity and qualitative ingredient semantics.
-- All multi-table recipe writes now happen in one transaction through an RPC.

alter table public.user_food_preferences enable row level security;
drop policy if exists "preferences own" on public.user_food_preferences;
create policy "preferences own"
on public.user_food_preferences
for all to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

alter table public.recipe_ingredients
  add column if not exists is_qualitative boolean not null default false;

create or replace function public.save_recipe_with_ingredients(
  p_recipe jsonb,
  p_ingredients jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  rid uuid;
  uid uuid := auth.uid();
  item jsonb;
  ingredient_name text;
  ingredient_quantity numeric;
  ingredient_unit text;
begin
  if uid is null then raise exception 'Nicht authentifiziert.'; end if;
  if jsonb_typeof(p_recipe) <> 'object' then raise exception 'Ungültige Rezeptdaten.'; end if;
  if jsonb_typeof(p_ingredients) <> 'array' then raise exception 'Ungültige Zutatenliste.'; end if;
  if coalesce(trim(p_recipe->>'name'),'') = '' then raise exception 'Ein Rezeptname ist erforderlich.'; end if;

  insert into public.recipes(
    created_by, name, description, servings, prep_time_minutes,
    cook_time_minutes, difficulty, instructions
  )
  values(
    uid,
    trim(p_recipe->>'name'),
    coalesce(p_recipe->>'description',''),
    greatest(coalesce((p_recipe->>'servings')::integer, 1), 1),
    greatest(coalesce((p_recipe->>'prep_time_minutes')::integer, 0), 0),
    greatest(coalesce((p_recipe->>'cook_time_minutes')::integer, 0), 0),
    coalesce(nullif(trim(p_recipe->>'difficulty'),''),'Einfach'),
    coalesce(p_recipe->'instructions','[]'::jsonb)
  )
  returning id into rid;

  for item in select value from jsonb_array_elements(p_ingredients) loop
    ingredient_name := trim(coalesce(item->>'name',''));
    ingredient_quantity := (item->>'quantity')::numeric;
    ingredient_unit := coalesce(item->>'unit','');
    if ingredient_name = '' then raise exception 'Eine Zutat benötigt einen Namen.'; end if;
    if ingredient_quantity is null or ingredient_quantity <= 0 then raise exception 'Zutatenmengen müssen positiv sein.'; end if;
    if ingredient_unit = '' then raise exception 'Eine Zutat benötigt eine Einheit.'; end if;

    insert into public.recipe_ingredients(
      recipe_id, food_id, name, quantity, unit,
      is_user_selected, is_additional, is_qualitative
    ) values (
      rid, nullif(item->>'food_id',''), ingredient_name, ingredient_quantity, ingredient_unit,
      coalesce((item->>'is_user_selected')::boolean,false),
      coalesce((item->>'is_additional')::boolean,false),
      coalesce((item->>'is_qualitative')::boolean,false)
    );
  end loop;

  insert into public.recipe_saves(recipe_id,user_id)
  values(rid,uid)
  on conflict do nothing;

  return rid;
end;
$$;

revoke all on function public.save_recipe_with_ingredients(jsonb,jsonb) from public, anon;
grant execute on function public.save_recipe_with_ingredients(jsonb,jsonb) to authenticated;

create or replace function public.add_favorite_recipe(
  p_name text,
  p_description text default '',
  p_instructions jsonb default '[]'::jsonb,
  p_ingredients jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  rid uuid;
  uid uuid := auth.uid();
  item jsonb;
begin
  if uid is null then raise exception 'Nicht authentifiziert.'; end if;
  if trim(coalesce(p_name,''))='' then raise exception 'Ein Rezeptname ist erforderlich.'; end if;

  insert into public.recipes(
    created_by, name, description, servings, prep_time_minutes,
    cook_time_minutes, difficulty, instructions
  ) values(uid,trim(p_name),coalesce(p_description,''),2,0,0,'easy',p_instructions)
  returning id into rid;

  for item in select value from jsonb_array_elements(coalesce(p_ingredients,'[]'::jsonb)) loop
    if coalesce(trim(item->>'name'),'') = '' then raise exception 'Eine Zutat benötigt einen Namen.'; end if;
    insert into public.recipe_ingredients(
      recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative
    ) values(
      rid,nullif(item->>'food_id',''),trim(item->>'name'),
      greatest(coalesce((item->>'quantity')::numeric,1),0.000001),
      coalesce(item->>'unit','Stück'),
      coalesce((item->>'is_user_selected')::boolean,false),
      coalesce((item->>'is_additional')::boolean,false),
      coalesce((item->>'is_qualitative')::boolean,false)
    );
  end loop;

  insert into public.recipe_saves(recipe_id,user_id) values(rid,uid) on conflict do nothing;
  return rid;
end;
$$;

revoke all on function public.add_favorite_recipe(text,text,jsonb) from public, anon, authenticated;
revoke all on function public.add_favorite_recipe(text,text,jsonb,jsonb) from public, anon;
grant execute on function public.add_favorite_recipe(text,text,jsonb,jsonb) to authenticated;
