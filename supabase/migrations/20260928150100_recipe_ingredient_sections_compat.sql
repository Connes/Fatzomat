-- Keep shared-recipe RPCs compatible with the deployed recipes table while
-- persisting the new ingredient section metadata.

create or replace function public.find_shared_recipe_duplicate(p_recipe jsonb,p_ingredients jsonb)
returns uuid language plpgsql security definer set search_path=public,pg_temp
as $$
declare uid uuid:=auth.uid(); cid uuid; duplicate_id uuid;
begin
 if uid is null then raise exception 'Nicht authentifiziert.'; end if;
 select cm.connection_id into cid from public.connection_members cm where cm.user_id=uid limit 1;
 if cid is null then raise exception 'Für gemeinsame Rezepte wird eine Verbindung benötigt.'; end if;
 select r.id into duplicate_id from public.recipes r
 where md5(lower(regexp_replace(trim(coalesce(r.name,'')),'\\s+',' ','g')) || '|' || coalesce((
   select string_agg(lower(regexp_replace(trim(coalesce(ri.section,'')),'\\s+',' ','g')) || ':' || lower(regexp_replace(trim(coalesce(ri.name,'')),'\\s+',' ','g')) || ':' || ri.quantity::text || ':' || lower(trim(coalesce(ri.unit,''))), '|' order by lower(regexp_replace(trim(coalesce(ri.section,'')),'\\s+',' ','g')),lower(regexp_replace(trim(coalesce(ri.name,'')),'\\s+',' ','g')),ri.quantity,lower(trim(coalesce(ri.unit,''))))
   from public.recipe_ingredients ri where ri.recipe_id=r.id),'')) = public.recipe_fingerprint(p_recipe,p_ingredients)
 and (r.created_by=uid or exists(select 1 from public.connection_members cm where cm.connection_id=cid and cm.user_id=r.created_by))
 order by r.created_at desc limit 1;
 return duplicate_id;
end;
$$;
revoke all on function public.find_shared_recipe_duplicate(jsonb,jsonb) from public,anon;
grant execute on function public.find_shared_recipe_duplicate(jsonb,jsonb) to authenticated;

create or replace function public.create_shared_recipe(p_recipe jsonb,p_ingredients jsonb,p_allow_duplicate boolean default false)
returns jsonb language plpgsql security definer set search_path=public,pg_temp
as $$
declare uid uuid:=auth.uid(); cid uuid; partner uuid; rid uuid; duplicate_id uuid; item jsonb; ingredient_name text; ingredient_quantity numeric; ingredient_unit text; ingredient_section text;
begin
 if uid is null then raise exception 'Nicht authentifiziert.'; end if;
 if jsonb_typeof(p_recipe)<>'object' then raise exception 'Ungültige Rezeptdaten.'; end if;
 if jsonb_typeof(p_ingredients)<>'array' or jsonb_array_length(p_ingredients)=0 then raise exception 'Ein Rezept benötigt mindestens eine Zutat.'; end if;
 if trim(coalesce(p_recipe->>'name',''))='' then raise exception 'Ein Rezeptname ist erforderlich.'; end if;
 select cm.connection_id into cid from public.connection_members cm where cm.user_id=uid limit 1;
 if cid is null then raise exception 'Für gemeinsame Rezepte wird eine Verbindung benötigt.'; end if;
 duplicate_id:=public.find_shared_recipe_duplicate(p_recipe,p_ingredients);
 if duplicate_id is not null and not coalesce(p_allow_duplicate,false) then return jsonb_build_object('created',false,'recipe_id',null,'duplicate_recipe_id',duplicate_id); end if;
 insert into public.recipes(created_by,name,description,servings,prep_time_minutes,cook_time_minutes,difficulty,instructions,image_url)
 values(uid,trim(p_recipe->>'name'),coalesce(p_recipe->>'description',''),greatest(coalesce((p_recipe->>'servings')::integer,1),1),greatest(coalesce((p_recipe->>'prep_time_minutes')::integer,0),0),greatest(coalesce((p_recipe->>'cook_time_minutes')::integer,0),0),coalesce(nullif(trim(p_recipe->>'difficulty'),''),'Einfach'),coalesce(p_recipe->'instructions','[]'::jsonb),nullif(trim(coalesce(p_recipe->>'image_url','')),'')) returning id into rid;
 for item in select value from jsonb_array_elements(p_ingredients) loop
  ingredient_name:=trim(coalesce(item->>'name','')); ingredient_quantity:=coalesce(nullif(item->>'quantity','')::numeric,nullif(item->>'amount','')::numeric,1); ingredient_unit:=trim(coalesce(item->>'unit','')); ingredient_section:=nullif(trim(coalesce(item->>'section','')),'');
  if ingredient_name='' then raise exception 'Eine Zutat benötigt einen Namen.'; end if;
  if ingredient_quantity is null or ingredient_quantity<=0 then raise exception 'Zutatenmengen müssen positiv sein.'; end if;
  if ingredient_unit='' then raise exception 'Eine Zutat benötigt eine Einheit.'; end if;
  if length(ingredient_section)>80 then raise exception 'Ein Zutatenabschnitt ist zu lang.'; end if;
  insert into public.recipe_ingredients(recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative,section) values(rid,nullif(item->>'food_id',''),ingredient_name,ingredient_quantity,ingredient_unit,coalesce((item->>'is_user_selected')::boolean,false),coalesce((item->>'is_additional')::boolean,false),coalesce((item->>'is_qualitative')::boolean,false),ingredient_section);
 end loop;
 insert into public.recipe_saves(recipe_id,user_id) select rid,cm.user_id from public.connection_members cm where cm.connection_id=cid on conflict do nothing;
 select cm.user_id into partner from public.connection_members cm where cm.connection_id=cid and cm.user_id<>uid limit 1;
 if partner is not null then insert into public.app_notifications(user_id,type,title,body,recipe_id) values(partner,'recipe_created','Neues Rezept',trim(p_recipe->>'name') || ' wurde zur gemeinsamen Rezeptsammlung hinzugefügt.',rid); end if;
 return jsonb_build_object('created',true,'recipe_id',rid,'duplicate_recipe_id',duplicate_id);
end;
$$;
revoke all on function public.create_shared_recipe(jsonb,jsonb,boolean) from public,anon;
grant execute on function public.create_shared_recipe(jsonb,jsonb,boolean) to authenticated;

create or replace function public.update_shared_recipe(p_recipe_id uuid,p_recipe jsonb,p_ingredients jsonb)
returns uuid language plpgsql security definer set search_path=public,pg_temp
as $$
declare uid uuid:=auth.uid(); cid uuid; owner_id uuid; duplicate_id uuid; item jsonb; ingredient_name text; ingredient_quantity numeric; ingredient_unit text; ingredient_section text;
begin
 if uid is null then raise exception 'Nicht authentifiziert.'; end if;
 select cm.connection_id into cid from public.connection_members cm where cm.user_id=uid limit 1;
 if cid is null then raise exception 'Für gemeinsame Rezepte wird eine Verbindung benötigt.'; end if;
 select r.created_by into owner_id from public.recipes r where r.id=p_recipe_id and (r.created_by=uid or exists(select 1 from public.connection_members cm where cm.connection_id=cid and cm.user_id=r.created_by)) for update;
 if owner_id is null then raise exception 'Rezept ist nicht verfügbar.'; end if;
 if trim(coalesce(p_recipe->>'name',''))='' then raise exception 'Ein Rezeptname ist erforderlich.'; end if;
 if jsonb_typeof(p_ingredients)<>'array' or jsonb_array_length(p_ingredients)=0 then raise exception 'Ein Rezept benötigt mindestens eine Zutat.'; end if;
 duplicate_id:=public.find_shared_recipe_duplicate(p_recipe,p_ingredients);
 if duplicate_id is not null and duplicate_id<>p_recipe_id then raise exception 'Dieses Rezept gibt es bereits in eurer gemeinsamen Rezeptsammlung.'; end if;
 update public.recipes set name=trim(p_recipe->>'name'),description=coalesce(p_recipe->>'description',''),servings=greatest(coalesce((p_recipe->>'servings')::integer,1),1),prep_time_minutes=greatest(coalesce((p_recipe->>'prep_time_minutes')::integer,0),0),cook_time_minutes=greatest(coalesce((p_recipe->>'cook_time_minutes')::integer,0),0),difficulty=coalesce(nullif(trim(p_recipe->>'difficulty'),''),'Einfach'),instructions=coalesce(p_recipe->'instructions','[]'::jsonb),image_url=nullif(trim(coalesce(p_recipe->>'image_url','')),'') where id=p_recipe_id;
 delete from public.recipe_ingredients where recipe_id=p_recipe_id;
 for item in select value from jsonb_array_elements(p_ingredients) loop
  ingredient_name:=trim(coalesce(item->>'name','')); ingredient_quantity:=coalesce(nullif(item->>'quantity','')::numeric,nullif(item->>'amount','')::numeric,1); ingredient_unit:=trim(coalesce(item->>'unit','')); ingredient_section:=nullif(trim(coalesce(item->>'section','')),'');
  if ingredient_name='' then raise exception 'Eine Zutat benötigt einen Namen.'; end if;
  if ingredient_quantity is null or ingredient_quantity<=0 then raise exception 'Zutatenmengen müssen positiv sein.'; end if;
  if ingredient_unit='' then raise exception 'Eine Zutat benötigt eine Einheit.'; end if;
  if length(ingredient_section)>80 then raise exception 'Ein Zutatenabschnitt ist zu lang.'; end if;
  insert into public.recipe_ingredients(recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative,section) values(p_recipe_id,nullif(item->>'food_id',''),ingredient_name,ingredient_quantity,ingredient_unit,coalesce((item->>'is_user_selected')::boolean,false),coalesce((item->>'is_additional')::boolean,false),coalesce((item->>'is_qualitative')::boolean,false),ingredient_section);
 end loop;
 return p_recipe_id;
end;
$$;
revoke all on function public.update_shared_recipe(uuid,jsonb,jsonb) from public,anon;
grant execute on function public.update_shared_recipe(uuid,jsonb,jsonb) to authenticated;
