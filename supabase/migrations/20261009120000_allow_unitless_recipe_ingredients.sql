-- Piece-count ingredients are intentionally stored with an empty unit.
-- The UI renders "2 Zwiebeln", not "2 Stück Zwiebeln". Keep the unit column
-- non-null, but allow the empty string in create/update RPCs.

create or replace function public.create_shared_recipe(
  p_recipe jsonb, p_ingredients jsonb, p_allow_duplicate boolean default false
) returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid(); partner uuid; rid uuid; duplicate_id uuid;
  fp text; item jsonb; ingredient_name text; ingredient_quantity numeric; ingredient_unit text;
begin
  if uid is null then raise exception 'Nicht authentifiziert.'; end if;
  if jsonb_typeof(p_recipe) <> 'object' then raise exception 'Ungültige Rezeptdaten.'; end if;
  if jsonb_typeof(p_ingredients) <> 'array' or jsonb_array_length(p_ingredients) = 0 then raise exception 'Ein Rezept benötigt mindestens eine Zutat.'; end if;
  if trim(coalesce(p_recipe->>'name','')) = '' then raise exception 'Ein Rezeptname ist erforderlich.'; end if;
  fp := public.recipe_fingerprint(p_recipe,p_ingredients);
  select id into duplicate_id from public.recipes where recipe_fingerprint=fp order by created_at desc limit 1;
  if duplicate_id is not null then
    return jsonb_build_object('created',false,'recipe_id',null,'duplicate_recipe_id',duplicate_id);
  end if;
  insert into public.recipes(created_by,name,description,servings,prep_time_minutes,cook_time_minutes,difficulty,instructions,image_url,updated_at,recipe_fingerprint)
  values(uid,trim(p_recipe->>'name'),coalesce(p_recipe->>'description',''),
    greatest(coalesce((p_recipe->>'servings')::integer,1),1),
    greatest(coalesce((p_recipe->>'prep_time_minutes')::integer,0),0),
    greatest(coalesce((p_recipe->>'cook_time_minutes')::integer,0),0),
    coalesce(nullif(trim(p_recipe->>'difficulty'),''),'Einfach'),
    coalesce(p_recipe->'instructions','[]'::jsonb),
    nullif(trim(coalesce(p_recipe->>'image_url','')),''),now(),fp)
  returning id into rid;
  for item in select value from jsonb_array_elements(p_ingredients) loop
    ingredient_name := trim(coalesce(item->>'name',''));
    ingredient_quantity := coalesce(nullif(item->>'quantity','')::numeric,nullif(item->>'amount','')::numeric,1);
    ingredient_unit := trim(coalesce(item->>'unit',''));
    if ingredient_name='' then raise exception 'Eine Zutat benötigt einen Namen.'; end if;
    if ingredient_quantity is null or ingredient_quantity<=0 then raise exception 'Zutatenmengen müssen positiv sein.'; end if;
    -- An empty unit is valid (e.g. "2 Zwiebeln"). Keep all other validation.
    insert into public.recipe_ingredients(recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative,section)
    values(rid,nullif(item->>'food_id',''),ingredient_name,ingredient_quantity,ingredient_unit,
      coalesce((item->>'is_user_selected')::boolean,false),coalesce((item->>'is_additional')::boolean,false),
      coalesce((item->>'is_qualitative')::boolean,false),nullif(item->>'section',''));
  end loop;
  insert into public.recipe_saves(recipe_id,user_id) values(rid,uid) on conflict do nothing;
  select cm.user_id into partner
  from public.connection_members mine join public.connection_members cm on cm.connection_id=mine.connection_id
  where mine.user_id=uid and cm.user_id<>uid limit 1;
  if partner is not null then
    insert into public.app_notifications(user_id,type,title,body,recipe_id)
    values(partner,'recipe_created','Neues Rezept','Ein neues Rezept wurde zur gemeinsamen Rezeptsammlung hinzugefügt: '||trim(p_recipe->>'name'),rid);
  end if;
  return jsonb_build_object('created',true,'recipe_id',rid,'duplicate_recipe_id',duplicate_id);
end $$;
revoke all on function public.create_shared_recipe(jsonb,jsonb,boolean) from public, anon;
grant execute on function public.create_shared_recipe(jsonb,jsonb,boolean) to authenticated;

create or replace function public.update_shared_recipe(p_recipe_id uuid,p_recipe jsonb,p_ingredients jsonb)
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare uid uuid:=auth.uid(); fp text; item jsonb; rid uuid; ingredient_name text; ingredient_quantity numeric; ingredient_unit text;
begin
  if uid is null then raise exception 'Nicht authentifiziert.'; end if;
  if not exists(select 1 from public.recipes where id=p_recipe_id) then raise exception 'Rezept ist nicht verfügbar.'; end if;
  if trim(coalesce(p_recipe->>'name',''))='' then raise exception 'Ein Rezeptname ist erforderlich.'; end if;
  if jsonb_typeof(p_ingredients)<>'array' or jsonb_array_length(p_ingredients)=0 then raise exception 'Ein Rezept benötigt mindestens eine Zutat.'; end if;
  fp:=public.recipe_fingerprint(p_recipe,p_ingredients);
  if exists(select 1 from public.recipes where id<>p_recipe_id and recipe_fingerprint=fp) then raise exception 'Dieses Rezept gibt es bereits in der gemeinsamen Rezeptsammlung.'; end if;
  update public.recipes set name=trim(p_recipe->>'name'),description=coalesce(p_recipe->>'description',''),
    servings=greatest(coalesce((p_recipe->>'servings')::integer,1),1),
    prep_time_minutes=greatest(coalesce((p_recipe->>'prep_time_minutes')::integer,0),0),
    cook_time_minutes=greatest(coalesce((p_recipe->>'cook_time_minutes')::integer,0),0),
    difficulty=coalesce(nullif(trim(p_recipe->>'difficulty'),''),'Einfach'),
    instructions=coalesce(p_recipe->'instructions','[]'::jsonb),
    image_url=nullif(trim(coalesce(p_recipe->>'image_url','')),''),recipe_fingerprint=fp,updated_at=now()
  where id=p_recipe_id returning id into rid;
  delete from public.recipe_ingredients where recipe_id=rid;
  for item in select value from jsonb_array_elements(p_ingredients) loop
    ingredient_name:=trim(coalesce(item->>'name',''));
    ingredient_quantity:=coalesce(nullif(item->>'quantity','')::numeric,nullif(item->>'amount','')::numeric,1);
    ingredient_unit:=trim(coalesce(item->>'unit',''));
    if ingredient_name='' or ingredient_quantity<=0 then raise exception 'Ungültige Zutat.'; end if;
    -- An empty unit is valid (e.g. "2 Zwiebeln").
    insert into public.recipe_ingredients(recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative,section)
    values(rid,nullif(item->>'food_id',''),ingredient_name,ingredient_quantity,ingredient_unit,
      coalesce((item->>'is_user_selected')::boolean,false),coalesce((item->>'is_additional')::boolean,false),
      coalesce((item->>'is_qualitative')::boolean,false),nullif(item->>'section',''));
  end loop;
  return rid;
end $$;
revoke all on function public.update_shared_recipe(uuid,jsonb,jsonb) from public, anon;
grant execute on function public.update_shared_recipe(uuid,jsonb,jsonb) to authenticated;
