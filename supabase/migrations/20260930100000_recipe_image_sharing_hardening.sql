-- Harden recipe image propagation for independent shared copies.


-- Shared recipe copies may intentionally reference the original private image
-- object. Access is still restricted by recipe ownership/connection/save access,
-- but the object path no longer has to match the current recipe's UUID folder.
drop policy if exists "recipe images accessible with recipe" on storage.objects;
create policy "recipe images accessible with recipe"
on storage.objects
for select to authenticated
using (
  bucket_id = 'recipe-images'
  and exists (
    select 1
    from public.recipes r
    where r.image_path = name
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
          select 1
          from public.recipe_saves rs
          where rs.recipe_id = r.id
            and rs.user_id = (select auth.uid())
        )
        or exists (
          select 1
          from public.shared_recipe_plans sp
          where sp.recipe_id = r.id
            and public.is_connection_member(sp.connection_id)
        )
      )
  )
);

create or replace function public.accept_decision_share(p_share_id uuid)
returns jsonb language plpgsql security definer set search_path=public,pg_temp
as $$
declare uid uuid:=auth.uid(); share_row public.decision_shares; source_recipe public.recipes; copied_recipe_id uuid; plan_id uuid;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  select * into share_row from public.decision_shares where id=p_share_id and recipient_id=uid and is_connection_member(connection_id) for update;
  if share_row.id is null then raise exception 'Die geteilte Entscheidung ist nicht mehr verfügbar.'; end if;
  if share_row.message_type<>'share' then raise exception 'Diese Nachricht enthält keine übernehmbare Entscheidung.'; end if;
  if share_row.cancelled_at is not null then raise exception 'Diese gemeinsame Entscheidung wurde bereits entfernt.'; end if;
  if share_row.plan_date<>current_date then raise exception 'Die geteilte Entscheidung gilt nicht mehr für heute.'; end if;
  if share_row.accepted_at is not null and share_row.accepted_plan_id is not null then
    return jsonb_build_object('share_id',share_row.id,'plan_id',share_row.accepted_plan_id,'decision_type',share_row.decision_type,'recipe_id',share_row.accepted_recipe_id);
  end if;

  if share_row.decision_type='recipe' then
    if share_row.recipe_id is null then raise exception 'Das geteilte Rezept ist nicht mehr verfügbar.'; end if;
    copied_recipe_id:=share_row.accepted_recipe_id;
    if copied_recipe_id is null then
      select * into source_recipe from public.recipes where id=share_row.recipe_id and created_by=share_row.sender_id for share;
      if source_recipe.id is null then raise exception 'Das geteilte Rezept ist nicht mehr verfügbar.'; end if;
      insert into public.recipes(created_by,name,description,servings,prep_time_minutes,cook_time_minutes,difficulty,instructions,image_url,image_path)
      values(uid,source_recipe.name,source_recipe.description,source_recipe.servings,source_recipe.prep_time_minutes,source_recipe.cook_time_minutes,source_recipe.difficulty,source_recipe.instructions,source_recipe.image_url,source_recipe.image_path)
      returning id into copied_recipe_id;
      insert into public.recipe_ingredients(recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative)
      select copied_recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative from public.recipe_ingredients where recipe_id=share_row.recipe_id;
      insert into public.recipe_saves(recipe_id,user_id) values(copied_recipe_id,uid) on conflict(recipe_id,user_id) do nothing;
    end if;
    plan_id:=public.set_personal_today_plan(copied_recipe_id,share_row.servings);
  elsif share_row.decision_type in ('order','dine_out','surprise') then
    if nullif(btrim(share_row.decision_value),'') is null then raise exception 'Die geteilte Entscheidung ist nicht mehr vollständig verfügbar.'; end if;
    plan_id:=public.set_personal_today_decision(share_row.decision_type,share_row.decision_value);
  else raise exception 'Ungültige geteilte Entscheidung.'; end if;

  update public.decision_shares set accepted_at=now(),accepted_plan_id=plan_id where id=share_row.id;
  return jsonb_build_object('share_id',share_row.id,'plan_id',plan_id,'decision_type',share_row.decision_type,'recipe_id',copied_recipe_id);
end; $$;

revoke all on function public.accept_decision_share(uuid) from public,anon;
grant execute on function public.accept_decision_share(uuid) to authenticated;


-- A normal client may only set/update an image object under its own recipe UUID.
-- Shared copies are created by the SECURITY DEFINER acceptance RPC above and may
-- reference the source object's path without granting arbitrary path selection.
drop policy if exists "recipe images owner update" on storage.objects;
create policy "recipe images owner update"
on storage.objects
for update to authenticated
using (
  bucket_id = 'recipe-images'
  and exists (
    select 1 from public.recipes r
    where r.id::text = (storage.foldername(name))[1]
      and r.created_by = (select auth.uid())
  )
)
with check (
  bucket_id = 'recipe-images'
  and exists (
    select 1 from public.recipes r
    where r.id::text = (storage.foldername(name))[1]
      and r.created_by = (select auth.uid())
  )
);

-- Prevent a normal client from pointing its own recipe at an arbitrary storage
-- object. The independent-copy RPC is SECURITY DEFINER and can preserve the
-- source image_path intentionally.
drop policy if exists "recipes own update" on public.recipes;
create policy "recipes own update"
on public.recipes
for update to authenticated
using (created_by = (select auth.uid()))
with check (
  created_by = (select auth.uid())
  and (
    image_path is null
    or image_path like id::text || '/%'
  )
);

drop policy if exists "recipes own insert" on public.recipes;
create policy "recipes own insert"
on public.recipes
for insert to authenticated
with check (
  created_by = (select auth.uid())
  and (
    image_path is null
    or image_path like id::text || '/%'
  )
);


create or replace function public.respond_to_recipe_suggestion(
  p_suggestion_id uuid,
  p_accept boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  row public.recipe_suggestions;
  source_recipe public.recipes;
  copied_recipe_id uuid;
  new_status text;
begin
  if uid is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  select * into row
  from public.recipe_suggestions
  where id = p_suggestion_id
    and suggested_to = uid
    and status = 'pending'
    and public.is_connection_member(connection_id)
  for update;

  if row.id is null then
    raise exception 'Der Rezeptvorschlag ist nicht mehr offen oder gehört nicht zu deiner Verbindung.';
  end if;

  if p_accept then
    select * into source_recipe
    from public.recipes
    where id = row.recipe_id
    for share;

    if source_recipe.id is null then
      raise exception 'Das geteilte Rezept ist nicht mehr verfügbar.';
    end if;

    insert into public.recipes(
      created_by, name, description, servings, prep_time_minutes,
      cook_time_minutes, difficulty, instructions, image_url, image_path
    )
    values (
      uid, source_recipe.name, source_recipe.description, source_recipe.servings,
      source_recipe.prep_time_minutes, source_recipe.cook_time_minutes,
      source_recipe.difficulty, source_recipe.instructions, source_recipe.image_url, source_recipe.image_path
    )
    returning id into copied_recipe_id;

    insert into public.recipe_ingredients(
      recipe_id, food_id, name, quantity, unit,
      is_user_selected, is_additional, is_qualitative
    )
    select
      copied_recipe_id, food_id, name, quantity, unit,
      is_user_selected, is_additional, is_qualitative
    from public.recipe_ingredients
    where recipe_id = row.recipe_id;

    insert into public.recipe_saves(recipe_id, user_id)
    values (copied_recipe_id, uid)
    on conflict (recipe_id, user_id) do nothing;

    new_status := 'accepted';
  else
    new_status := 'declined';
  end if;

  update public.recipe_suggestions
  set status = new_status,
      responded_at = now()
  where id = row.id;

  update public.app_notifications
  set read_at = coalesce(read_at, now())
  where recipe_suggestion_id = row.id
    and user_id = uid;

  row.status := new_status;
  row.responded_at := now();

  return jsonb_build_object(
    'id', row.id,
    'connection_id', row.connection_id,
    'recipe_id', row.recipe_id,
    'suggested_by', row.suggested_by,
    'suggested_to', row.suggested_to,
    'status', row.status,
    'created_at', row.created_at,
    'responded_at', row.responded_at,
    'copied_recipe_id', copied_recipe_id
  );
end;
$$;

revoke all on function public.respond_to_recipe_suggestion(uuid,boolean) from public,anon;
grant execute on function public.respond_to_recipe_suggestion(uuid,boolean) to authenticated;
