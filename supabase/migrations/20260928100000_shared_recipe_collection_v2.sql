-- Shared recipe collection v2.
-- The connected pair owns one recipe collection. Recipe suggestions remain in
-- the historical schema but are no longer part of the active app workflow.

alter table public.recipes
  add column if not exists updated_at timestamptz not null default now();

alter table public.recipes
  add column if not exists recipe_fingerprint text;

create index if not exists idx_recipes_connection_fingerprint
  on public.recipes(recipe_fingerprint, created_by);

-- A connection grants read access to all recipes created by either member.
-- Write operations go through the security-definer RPCs below so the two-user
-- boundary cannot be widened by direct table writes.
drop policy if exists "recipes personal or explicitly shared read" on public.recipes;
drop policy if exists "recipes owner or shared" on public.recipes;
drop policy if exists "recipes collection read" on public.recipes;
create policy "recipes connection collection read"
on public.recipes for select to authenticated
using (
  created_by = (select auth.uid())
  or exists (
    select 1
    from public.connection_members own_cm
    join public.connection_members recipe_cm
      on recipe_cm.connection_id = own_cm.connection_id
    where own_cm.user_id = (select auth.uid())
      and recipe_cm.user_id = recipes.created_by
  )
  or exists (
    select 1
    from public.recipe_saves rs
    where rs.recipe_id = recipes.id
      and rs.user_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.shared_recipe_plans sp
    where sp.recipe_id = recipes.id
      and public.is_connection_member(sp.connection_id)
  )
);

drop policy if exists "recipe ingredients personal or explicitly shared read" on public.recipe_ingredients;
drop policy if exists "recipe ingredients readable for collection" on public.recipe_ingredients;
create policy "recipe ingredients connection collection read"
on public.recipe_ingredients for select to authenticated
using (
  exists (
    select 1
    from public.recipes r
    where r.id = recipe_ingredients.recipe_id
      and (
        r.created_by = (select auth.uid())
        or exists (
          select 1
          from public.connection_members own_cm
          join public.connection_members recipe_cm
            on recipe_cm.connection_id = own_cm.connection_id
          where own_cm.user_id = (select auth.uid())
            and recipe_cm.user_id = r.created_by
        )
        or exists (
          select 1 from public.recipe_saves rs
          where rs.recipe_id = r.id and rs.user_id = (select auth.uid())
        )
        or exists (
          select 1 from public.shared_recipe_plans sp
          where sp.recipe_id = r.id
            and public.is_connection_member(sp.connection_id)
        )
      )
  )
);

-- Keep the old save table compatible with existing Today/RPC paths, but make
-- it readable for both members of the same connection. New shared recipes
-- receive a save row for both members automatically.
drop policy if exists "recipe saves own read" on public.recipe_saves;
drop policy if exists "recipe saves shared" on public.recipe_saves;
create policy "recipe saves connection read"
on public.recipe_saves for select to authenticated
using (
  user_id = (select auth.uid())
  or exists (
    select 1
    from public.connection_members own_cm
    join public.connection_members recipe_cm
      on recipe_cm.connection_id = own_cm.connection_id
    where own_cm.user_id = (select auth.uid())
      and recipe_cm.user_id = recipe_saves.user_id
  )
);

-- Make personal Today compatible with any recipe in the connected collection.
create or replace function public.set_personal_today_plan(p_recipe_id uuid, p_servings integer default null)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  pid uuid;
  base_servings integer;
  target_servings integer;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;

  select r.servings into base_servings
  from public.recipes r
  where r.id = p_recipe_id
    and (
      r.created_by = uid
      or exists (select 1 from public.recipe_saves rs where rs.recipe_id = r.id and rs.user_id = uid)
      or exists (
        select 1
        from public.connection_members own_cm
        join public.connection_members recipe_cm on recipe_cm.connection_id = own_cm.connection_id
        where own_cm.user_id = uid and recipe_cm.user_id = r.created_by
      )
    )
  limit 1;

  if base_servings is null then raise exception 'Rezept ist nicht verfügbar.'; end if;
  target_servings := coalesce(p_servings, base_servings);
  if target_servings < 1 or target_servings > 12 then raise exception 'Ungültige Personenzahl.'; end if;

  select p.id into pid
  from public.personal_today_plans p
  where p.user_id = uid and p.plan_date = current_date and p.status <> 'cancelled'
  limit 1;

  if pid is null then
    insert into public.personal_today_plans(user_id,recipe_id,plan_date,status,servings)
    values(uid,p_recipe_id,current_date,'planned',target_servings)
    returning id into pid;
  else
    update public.personal_today_plans
    set recipe_id=p_recipe_id,status='planned',servings=target_servings,updated_at=now()
    where id=pid and user_id=uid;
  end if;

  delete from public.shopping_items where personal_today_plan_id=pid and source='recipe';
  insert into public.shopping_items(personal_today_plan_id,food_id,name,quantity,unit,source)
  select pid,ri.food_id,ri.name,
         round((ri.quantity*target_servings::numeric/greatest(base_servings,1))::numeric,2),
         ri.unit,'recipe'
  from public.recipe_ingredients ri
  where ri.recipe_id=p_recipe_id;

  return pid;
end;
$$;
revoke all on function public.set_personal_today_plan(uuid,integer) from public, anon;
grant execute on function public.set_personal_today_plan(uuid,integer) to authenticated;

-- Shared recipe fingerprint. It intentionally ignores ingredient ordering and
-- descriptions so the common duplicate check catches the same recipe even if
-- an importer or ChatGPT returns the ingredients in a different order.
create or replace function public.recipe_fingerprint(p_recipe jsonb, p_ingredients jsonb)
returns text
language sql
immutable
as $$
  select md5(
    lower(regexp_replace(trim(coalesce(p_recipe->>'name','')), '\\s+', ' ', 'g'))
    || '|' || coalesce((
      select string_agg(
        lower(regexp_replace(trim(coalesce(item->>'name','')), '\\s+', ' ', 'g'))
        || ':'
        || coalesce(nullif(item->>'amount','')::numeric, nullif(item->>'quantity','')::numeric, 1)::text
        || ':'
        || lower(trim(coalesce(item->>'unit',''))),
        '|' order by
          lower(regexp_replace(trim(coalesce(item->>'name','')), '\\s+', ' ', 'g')),
          coalesce(nullif(item->>'amount','')::numeric, nullif(item->>'quantity','')::numeric, 1),
          lower(trim(coalesce(item->>'unit','')))
      )
      from jsonb_array_elements(coalesce(p_ingredients,'[]'::jsonb)) as values(item)
    ), '')
  );
$$;

revoke all on function public.recipe_fingerprint(jsonb,jsonb) from public, anon;
grant execute on function public.recipe_fingerprint(jsonb,jsonb) to authenticated;

-- Backfill fingerprints for recipes already in the collection so duplicate
-- detection also works against historical data.
update public.recipes r
set recipe_fingerprint = public.recipe_fingerprint(
  jsonb_build_object('name', r.name),
  coalesce((
    select jsonb_agg(jsonb_build_object(
      'name', ri.name,
      'amount', ri.quantity,
      'unit', ri.unit
    ) order by ri.name, ri.quantity, ri.unit)
    from public.recipe_ingredients ri
    where ri.recipe_id = r.id
  ), '[]'::jsonb)
)
where r.recipe_fingerprint is null;

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
  fingerprint := public.recipe_fingerprint(p_recipe,p_ingredients);

  select r.id into duplicate_id
  from public.recipes r
  where r.recipe_fingerprint = fingerprint
    and (
      r.created_by = uid
      or exists (
        select 1
        from public.connection_members own_cm
        join public.connection_members recipe_cm on recipe_cm.connection_id = own_cm.connection_id
        where own_cm.user_id = uid and recipe_cm.user_id = r.created_by
      )
    )
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
  cid uuid;
  partner uuid;
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
  if jsonb_typeof(p_ingredients) <> 'array' or jsonb_array_length(p_ingredients) = 0 then raise exception 'Ein Rezept benötigt mindestens eine Zutat.'; end if;
  if trim(coalesce(p_recipe->>'name','')) = '' then raise exception 'Ein Rezeptname ist erforderlich.'; end if;

  select cm.connection_id into cid
  from public.connection_members cm
  where cm.user_id=uid
  limit 1;
  if cid is null then raise exception 'Für gemeinsame Rezepte wird eine Verbindung benötigt.'; end if;

  fingerprint := public.recipe_fingerprint(p_recipe,p_ingredients);
  select r.id into duplicate_id
  from public.recipes r
  where r.recipe_fingerprint=fingerprint
    and (
      r.created_by=uid
      or exists (
        select 1 from public.connection_members cm
        where cm.connection_id=cid and cm.user_id=r.created_by
      )
    )
  order by r.created_at desc
  limit 1;

  if duplicate_id is not null and not coalesce(p_allow_duplicate,false) then
    return jsonb_build_object(
      'created', false,
      'recipe_id', null,
      'duplicate_recipe_id', duplicate_id
    );
  end if;

  insert into public.recipes(
    created_by,name,description,servings,prep_time_minutes,cook_time_minutes,difficulty,instructions,image_url,updated_at,recipe_fingerprint
  ) values(
    uid,
    trim(p_recipe->>'name'),
    coalesce(p_recipe->>'description',''),
    greatest(coalesce((p_recipe->>'servings')::integer,1),1),
    greatest(coalesce((p_recipe->>'prep_time_minutes')::integer,0),0),
    greatest(coalesce((p_recipe->>'cook_time_minutes')::integer,0),0),
    coalesce(nullif(trim(p_recipe->>'difficulty'),''),'Einfach'),
    coalesce(p_recipe->'instructions','[]'::jsonb),
    nullif(trim(coalesce(p_recipe->>'image_url','')),''),
    now(),
    fingerprint
  ) returning id into rid;

  for item in select value from jsonb_array_elements(p_ingredients) loop
    ingredient_name := trim(coalesce(item->>'name',''));
    ingredient_quantity := coalesce(nullif(item->>'quantity','')::numeric, nullif(item->>'amount','')::numeric, 1);
    ingredient_unit := trim(coalesce(item->>'unit',''));
    if ingredient_name='' then raise exception 'Eine Zutat benötigt einen Namen.'; end if;
    if ingredient_quantity is null or ingredient_quantity <= 0 then raise exception 'Zutatenmengen müssen positiv sein.'; end if;
    if ingredient_unit='' then raise exception 'Eine Zutat benötigt eine Einheit.'; end if;

    insert into public.recipe_ingredients(
      recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative
    ) values(
      rid,nullif(item->>'food_id',''),ingredient_name,ingredient_quantity,ingredient_unit,
      coalesce((item->>'is_user_selected')::boolean,false),
      coalesce((item->>'is_additional')::boolean,false),
      coalesce((item->>'is_qualitative')::boolean,false)
    );
  end loop;

  insert into public.recipe_saves(recipe_id,user_id)
  select rid, cm.user_id from public.connection_members cm where cm.connection_id=cid
  on conflict do nothing;

  select cm.user_id into partner
  from public.connection_members cm
  where cm.connection_id=cid and cm.user_id<>uid
  limit 1;

  if partner is not null then
    insert into public.app_notifications(user_id,type,title,body,recipe_id)
    values(
      partner,
      'recipe_created',
      'Neues Rezept',
      trim(p_recipe->>'name') || ' wurde zur gemeinsamen Rezeptsammlung hinzugefügt.',
      rid
    );
  end if;

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
  cid uuid;
  owner_id uuid;
  fingerprint text;
  item jsonb;
  ingredient_name text;
  ingredient_quantity numeric;
  ingredient_unit text;
begin
  if uid is null then raise exception 'Nicht authentifiziert.'; end if;
  select cm.connection_id into cid from public.connection_members cm where cm.user_id=uid limit 1;
  if cid is null then raise exception 'Für gemeinsame Rezepte wird eine Verbindung benötigt.'; end if;

  select r.created_by into owner_id
  from public.recipes r
  where r.id=p_recipe_id
    and (
      r.created_by=uid
      or exists(select 1 from public.connection_members cm where cm.connection_id=cid and cm.user_id=r.created_by)
    )
  for update;
  if owner_id is null then raise exception 'Rezept ist nicht verfügbar.'; end if;

  if trim(coalesce(p_recipe->>'name',''))='' then raise exception 'Ein Rezeptname ist erforderlich.'; end if;
  if jsonb_typeof(p_ingredients)<>'array' or jsonb_array_length(p_ingredients)=0 then raise exception 'Ein Rezept benötigt mindestens eine Zutat.'; end if;
  fingerprint := public.recipe_fingerprint(p_recipe,p_ingredients);

  if exists (
    select 1 from public.recipes r
    where r.id <> p_recipe_id
      and r.recipe_fingerprint = fingerprint
      and exists (select 1 from public.connection_members cm where cm.connection_id=cid and cm.user_id=r.created_by)
  ) then
    raise exception 'Dieses Rezept gibt es bereits in eurer gemeinsamen Rezeptsammlung.';
  end if;

  update public.recipes set
    name=trim(p_recipe->>'name'),
    description=coalesce(p_recipe->>'description',''),
    servings=greatest(coalesce((p_recipe->>'servings')::integer,1),1),
    prep_time_minutes=greatest(coalesce((p_recipe->>'prep_time_minutes')::integer,0),0),
    cook_time_minutes=greatest(coalesce((p_recipe->>'cook_time_minutes')::integer,0),0),
    difficulty=coalesce(nullif(trim(p_recipe->>'difficulty'),''),'Einfach'),
    instructions=coalesce(p_recipe->'instructions','[]'::jsonb),
    image_url=nullif(trim(coalesce(p_recipe->>'image_url','')),''),
    updated_at=now(),
    recipe_fingerprint=fingerprint
  where id=p_recipe_id;

  delete from public.recipe_ingredients where recipe_id=p_recipe_id;

  for item in select value from jsonb_array_elements(p_ingredients) loop
    ingredient_name:=trim(coalesce(item->>'name',''));
    ingredient_quantity:=coalesce(nullif(item->>'quantity','')::numeric,nullif(item->>'amount','')::numeric,1);
    ingredient_unit:=trim(coalesce(item->>'unit',''));
    if ingredient_name='' then raise exception 'Eine Zutat benötigt einen Namen.'; end if;
    if ingredient_quantity is null or ingredient_quantity<=0 then raise exception 'Zutatenmengen müssen positiv sein.'; end if;
    if ingredient_unit='' then raise exception 'Eine Zutat benötigt eine Einheit.'; end if;
    insert into public.recipe_ingredients(recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative)
    values(p_recipe_id,nullif(item->>'food_id',''),ingredient_name,ingredient_quantity,ingredient_unit,
      coalesce((item->>'is_user_selected')::boolean,false),coalesce((item->>'is_additional')::boolean,false),coalesce((item->>'is_qualitative')::boolean,false));
  end loop;

  return p_recipe_id;
end;
$$;
revoke all on function public.update_shared_recipe(uuid,jsonb,jsonb) from public, anon;
grant execute on function public.update_shared_recipe(uuid,jsonb,jsonb) to authenticated;

create or replace function public.remove_shared_recipe(p_recipe_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  cid uuid;
  recipe_name text;
  active_plan boolean;
begin
  if uid is null then raise exception 'Nicht authentifiziert.'; end if;
  select cm.connection_id into cid from public.connection_members cm where cm.user_id=uid limit 1;
  if cid is null then raise exception 'Für gemeinsame Rezepte wird eine Verbindung benötigt.'; end if;

  select r.name into recipe_name
  from public.recipes r
  where r.id=p_recipe_id
    and exists(select 1 from public.connection_members cm where cm.connection_id=cid and cm.user_id=r.created_by)
  for update;
  if recipe_name is null then raise exception 'Rezept ist nicht verfügbar.'; end if;

  select exists(
    select 1 from public.shared_recipe_plans sp
    where sp.recipe_id=p_recipe_id and sp.connection_id=cid and sp.status<>'cancelled'
  ) into active_plan;
  if active_plan then raise exception 'Das Rezept ist aktuell für heute eingeplant und kann nicht gelöscht werden.'; end if;

  delete from public.recipe_saves where recipe_id=p_recipe_id;
  delete from public.recipes where id=p_recipe_id;

  return true;
end;
$$;
revoke all on function public.remove_shared_recipe(uuid) from public, anon;
grant execute on function public.remove_shared_recipe(uuid) to authenticated;

-- Realtime is required for inserts/updates/deletes on the shared collection.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='recipes'
  ) then
    alter publication supabase_realtime add table public.recipes;
  end if;
end $$;
