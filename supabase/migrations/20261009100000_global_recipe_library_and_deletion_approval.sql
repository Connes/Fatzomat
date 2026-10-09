-- Global recipe library: recipes are app data, not account-owned copies.
-- Keep created_by only as nullable historical attribution. Deleting an auth user
-- must never delete the recipe itself.
alter table public.recipes alter column created_by drop not null;

do $$
declare fk_name text;
begin
  select con.conname into fk_name
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  join pg_namespace ns on ns.oid = rel.relnamespace
  where ns.nspname = 'public' and rel.relname = 'recipes'
    and con.contype = 'f'
    and con.confrelid = 'auth.users'::regclass
    and pg_get_constraintdef(con.oid) like '%(created_by)%'
  limit 1;
  if fk_name is not null then
    execute format('alter table public.recipes drop constraint %I', fk_name);
  end if;
end $$;
alter table public.recipes
  add constraint recipes_created_by_fkey
  foreign key (created_by) references auth.users(id) on delete set null;

-- The library and ingredients are readable by every authenticated user.
drop policy if exists "recipes connection collection read" on public.recipes;
drop policy if exists "recipes owner or shared" on public.recipes;
drop policy if exists "recipes personal or explicitly shared read" on public.recipes;
drop policy if exists "recipes collection read" on public.recipes;
create policy "recipes global library read"
on public.recipes for select to authenticated using (true);

drop policy if exists "recipe ingredients connection collection read" on public.recipe_ingredients;
drop policy if exists "recipe ingredients personal or explicitly shared read" on public.recipe_ingredients;
drop policy if exists "recipe ingredients readable for collection" on public.recipe_ingredients;
create policy "recipe ingredients global library read"
on public.recipe_ingredients for select to authenticated using (true);

-- Personal saves remain personal preferences, not access grants or ownership.
drop policy if exists "recipe saves connection read" on public.recipe_saves;
drop policy if exists "recipe saves own read" on public.recipe_saves;
create policy "recipe saves own read"
on public.recipe_saves for select to authenticated using (user_id = (select auth.uid()));

create table if not exists public.recipe_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  requested_by uuid references auth.users(id) on delete set null,
  requested_for uuid references auth.users(id) on delete set null,
  connection_id uuid references public.connections(id) on delete set null,
  status text not null default 'pending' check (status in ('pending','approved','rejected','cancelled')),
  created_at timestamptz not null default now(),
  responded_at timestamptz
);
create unique index if not exists recipe_deletion_one_pending_per_recipe
  on public.recipe_deletion_requests(recipe_id) where status = 'pending';
create index if not exists recipe_deletion_requests_recipient
  on public.recipe_deletion_requests(requested_for, status, created_at desc);
alter table public.recipe_deletion_requests enable row level security;
drop policy if exists "recipe deletion requests participants read" on public.recipe_deletion_requests;
create policy "recipe deletion requests participants read"
on public.recipe_deletion_requests for select to authenticated
using (requested_by = (select auth.uid()) or requested_for = (select auth.uid()));

create or replace function public.find_shared_recipe_duplicate(p_recipe jsonb, p_ingredients jsonb)
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare uid uuid := auth.uid(); fp text; rid uuid;
begin
  if uid is null then raise exception 'Nicht authentifiziert.'; end if;
  fp := public.recipe_fingerprint(p_recipe, p_ingredients);
  select id into rid from public.recipes where recipe_fingerprint = fp order by created_at desc limit 1;
  return rid;
end $$;
revoke all on function public.find_shared_recipe_duplicate(jsonb,jsonb) from public, anon;
grant execute on function public.find_shared_recipe_duplicate(jsonb,jsonb) to authenticated;

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
  if duplicate_id is not null and not coalesce(p_allow_duplicate,false) then
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
    if ingredient_unit='' then raise exception 'Eine Zutat benötigt eine Einheit.'; end if;
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
    if ingredient_name='' or ingredient_unit='' or ingredient_quantity<=0 then raise exception 'Ungültige Zutat.'; end if;
    insert into public.recipe_ingredients(recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative,section)
    values(rid,nullif(item->>'food_id',''),ingredient_name,ingredient_quantity,ingredient_unit,
      coalesce((item->>'is_user_selected')::boolean,false),coalesce((item->>'is_additional')::boolean,false),
      coalesce((item->>'is_qualitative')::boolean,false),nullif(item->>'section',''));
  end loop;
  return rid;
end $$;
revoke all on function public.update_shared_recipe(uuid,jsonb,jsonb) from public, anon;
grant execute on function public.update_shared_recipe(uuid,jsonb,jsonb) to authenticated;

-- If no partner exists, delete directly. With a connection, create a durable
-- request and notify the partner; the recipe remains until explicit approval.
drop function if exists public.remove_recipe_from_collection(uuid);
create or replace function public.remove_recipe_from_collection(p_recipe_id uuid)
returns boolean language plpgsql security definer set search_path = public, pg_temp as $$
declare uid uuid:=auth.uid(); cid uuid; partner uuid; pending_id uuid; recipe_name text;
begin
  if uid is null then raise exception 'Nicht authentifiziert.'; end if;
  select name into recipe_name from public.recipes where id=p_recipe_id for update;
  if recipe_name is null then raise exception 'Rezept ist nicht verfügbar.'; end if;
  select mine.connection_id, other.user_id into cid,partner
  from public.connection_members mine
  left join public.connection_members other on other.connection_id=mine.connection_id and other.user_id<>uid
  where mine.user_id=uid limit 1;
  if partner is null then
    delete from public.recipes where id=p_recipe_id;
    return true;
  end if;
  select id into pending_id from public.recipe_deletion_requests where recipe_id=p_recipe_id and status='pending' limit 1;
  if pending_id is not null then return false; end if;
  insert into public.recipe_deletion_requests(recipe_id,requested_by,requested_for,connection_id)
  values(p_recipe_id,uid,partner,cid) returning id into pending_id;
  insert into public.app_notifications(user_id,type,title,body,recipe_id,recipe_deletion_request_id)
  values(partner,'recipe_deletion_request','Löschung bestätigen','Die Löschung des Rezepts „'||recipe_name||'“ wird angefragt.',p_recipe_id,pending_id);
  return false;
end $$;
revoke all on function public.remove_recipe_from_collection(uuid) from public, anon;
grant execute on function public.remove_recipe_from_collection(uuid) to authenticated;

create or replace function public.respond_to_recipe_deletion(p_request_id uuid,p_approve boolean)
returns boolean language plpgsql security definer set search_path = public, pg_temp as $$
declare uid uuid:=auth.uid(); req public.recipe_deletion_requests; recipe_name text;
begin
  if uid is null then raise exception 'Nicht authentifiziert.'; end if;
  select * into req from public.recipe_deletion_requests where id=p_request_id for update;
  if req.id is null or req.requested_for<>uid or req.status<>'pending' then raise exception 'Die Löschanfrage ist nicht mehr offen oder gehört nicht zu dir.'; end if;
  if req.connection_id is null or not public.is_connection_member(req.connection_id,uid) then raise exception 'Du gehörst nicht mehr zu dieser Verbindung.'; end if;
  select name into recipe_name from public.recipes where id=req.recipe_id;
  update public.recipe_deletion_requests set status=case when p_approve then 'approved' else 'rejected' end,responded_at=now() where id=req.id;
  update public.app_notifications set read_at=coalesce(read_at,now()) where user_id=uid and type='recipe_deletion_request' and recipe_id=req.recipe_id;
  if p_approve then
    delete from public.recipes where id=req.recipe_id;
    insert into public.app_notifications(user_id,type,title,body)
    values(req.requested_by,'recipe_deletion_approved','Rezept gelöscht','Die Löschung von „'||coalesce(recipe_name,'Rezept')||'“ wurde bestätigt.');
  else
    insert into public.app_notifications(user_id,type,title,body,recipe_id)
    values(req.requested_by,'recipe_deletion_rejected','Löschung abgelehnt','Die Löschung von „'||coalesce(recipe_name,'Rezept')||'“ wurde abgelehnt.',req.recipe_id);
  end if;
  return p_approve;
end $$;
revoke all on function public.respond_to_recipe_deletion(uuid,boolean) from public, anon;
grant execute on function public.respond_to_recipe_deletion(uuid,boolean) to authenticated;

-- Private recipe images are part of the global library, so authenticated users
-- can read them regardless of who uploaded them.
drop policy if exists "recipe images accessible with recipe" on storage.objects;
create policy "recipe images accessible with recipe"
on storage.objects for select to authenticated
using (bucket_id='recipe-images' and exists(select 1 from public.recipes r where r.image_path=storage.objects.name));


-- Notification records carry the actionable deletion request identifier.
alter table public.app_notifications
  add column if not exists recipe_deletion_request_id uuid
  references public.recipe_deletion_requests(id) on delete cascade;
create index if not exists idx_notifications_recipe_deletion_request
  on public.app_notifications(recipe_deletion_request_id)
  where recipe_deletion_request_id is not null;

-- A suggestion now points at the shared recipe itself. Accepting it records
-- the decision only; it never creates a second recipes row.
create or replace function public.create_recipe_suggestion(p_recipe_id uuid)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare
  uid uuid:=auth.uid(); cid uuid; recipient uuid; row public.recipe_suggestions; recipe_name text; created_new boolean:=false;
begin
  if uid is null then raise exception 'Nicht authentifiziert.'; end if;
  select connection_id into cid from public.connection_members where user_id=uid limit 1;
  if cid is null then raise exception 'Keine Verbindung zu einer zweiten Person vorhanden.'; end if;
  select user_id into recipient from public.connection_members where connection_id=cid and user_id<>uid limit 1;
  if recipient is null then raise exception 'Keine verbundene Person vorhanden.'; end if;
  select name into recipe_name from public.recipes where id=p_recipe_id;
  if recipe_name is null then raise exception 'Das Rezept ist nicht verfügbar.'; end if;
  select * into row from public.recipe_suggestions
   where connection_id=cid and recipe_id=p_recipe_id and suggested_by=uid and suggested_to=recipient and status='pending'
   limit 1;
  if row.id is null then
    insert into public.recipe_suggestions(connection_id,recipe_id,suggested_by,suggested_to)
    values(cid,p_recipe_id,uid,recipient) returning * into row;
    created_new:=true;
  end if;
  if created_new then
    insert into public.app_notifications(user_id,type,title,body,recipe_id,recipe_suggestion_id)
    values(recipient,'recipe_suggestion','Rezept geteilt','Ein Rezept wurde mit dir geteilt: '||recipe_name,p_recipe_id,row.id);
  end if;
  return jsonb_build_object('id',row.id,'connection_id',row.connection_id,'recipe_id',row.recipe_id,
    'suggested_by',row.suggested_by,'suggested_to',row.suggested_to,'status',row.status,
    'created_at',row.created_at,'responded_at',row.responded_at);
end $$;
revoke all on function public.create_recipe_suggestion(uuid) from public,anon;
grant execute on function public.create_recipe_suggestion(uuid) to authenticated;

create or replace function public.respond_to_recipe_suggestion(p_suggestion_id uuid,p_accept boolean)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); row public.recipe_suggestions; new_status text;
begin
  if uid is null then raise exception 'Nicht authentifiziert.'; end if;
  select * into row from public.recipe_suggestions
  where id=p_suggestion_id and suggested_to=uid and status='pending'
    and public.is_connection_member(connection_id) for update;
  if row.id is null then raise exception 'Der Rezeptvorschlag ist nicht mehr offen oder gehört nicht zu deiner Verbindung.'; end if;
  new_status:=case when p_accept then 'accepted' else 'declined' end;
  update public.recipe_suggestions set status=new_status,responded_at=now() where id=row.id;
  update public.app_notifications set read_at=coalesce(read_at,now())
    where recipe_suggestion_id=row.id and user_id=uid;
  row.status:=new_status; row.responded_at:=now();
  return jsonb_build_object('id',row.id,'connection_id',row.connection_id,'recipe_id',row.recipe_id,
    'suggested_by',row.suggested_by,'suggested_to',row.suggested_to,'status',row.status,
    'created_at',row.created_at,'responded_at',row.responded_at);
end $$;
revoke all on function public.respond_to_recipe_suggestion(uuid,boolean) from public,anon;
grant execute on function public.respond_to_recipe_suggestion(uuid,boolean) to authenticated;

-- Recipe image objects follow the shared library's visibility, not account ownership.
drop policy if exists "recipe images owner insert" on storage.objects;
drop policy if exists "recipe images owner update" on storage.objects;
drop policy if exists "recipe images owner delete" on storage.objects;
create policy "recipe images global insert"
on storage.objects for insert to authenticated
with check (bucket_id='recipe-images');
create policy "recipe images global update"
on storage.objects for update to authenticated
using (bucket_id='recipe-images')
with check (bucket_id='recipe-images');
create policy "recipe images global delete"
on storage.objects for delete to authenticated
using (bucket_id='recipe-images');
