-- Recipe sharing v3: accepting a shared recipe creates an independent personal copy.
-- The sender remains the owner of the original recipe; the receiver owns the copy.

create or replace function public.create_recipe_suggestion(p_recipe_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  cid uuid;
  recipient uuid;
  row public.recipe_suggestions;
  recipe_name text;
  sender_name text;
  created_new boolean := false;
begin
  if uid is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  select cm.connection_id into cid
  from public.connection_members cm
  where cm.user_id = uid
  limit 1;

  if cid is null then
    raise exception 'Keine Verbindung zu einer zweiten Person vorhanden.';
  end if;

  select cm.user_id into recipient
  from public.connection_members cm
  where cm.connection_id = cid
    and cm.user_id <> uid
  limit 1;

  if recipient is null then
    raise exception 'Keine verbundene Person vorhanden.';
  end if;

  select r.name into recipe_name
  from public.recipes r
  where r.id = p_recipe_id
    and r.created_by = uid;

  if recipe_name is null then
    raise exception 'Du kannst nur eigene Rezepte teilen.';
  end if;

  select * into row
  from public.recipe_suggestions rs
  where rs.connection_id = cid
    and rs.recipe_id = p_recipe_id
    and rs.suggested_by = uid
    and rs.suggested_to = recipient
    and rs.status = 'pending'
  limit 1;

  if row.id is null then
    insert into public.recipe_suggestions(connection_id, recipe_id, suggested_by, suggested_to)
    values (cid, p_recipe_id, uid, recipient)
    returning * into row;
    created_new := true;
  end if;

  if created_new then
    select nullif(btrim(p.display_name), '') into sender_name
    from public.profiles p
    where p.id = uid;

    insert into public.app_notifications(
      user_id, type, title, body, recipe_id, recipe_suggestion_id
    )
    values (
      recipient,
      'recipe_suggestion',
      'Neues Rezept erhalten',
      coalesce(sender_name, 'Deine Verbindung') || ' hat dir „' || recipe_name || '“ geschickt.',
      p_recipe_id,
      row.id
    );
  end if;

  return jsonb_build_object(
    'id', row.id,
    'connection_id', row.connection_id,
    'recipe_id', row.recipe_id,
    'suggested_by', row.suggested_by,
    'suggested_to', row.suggested_to,
    'status', row.status,
    'created_at', row.created_at,
    'responded_at', row.responded_at,
    'sender_name', sender_name
  );
end;
$$;

revoke all on function public.create_recipe_suggestion(uuid) from public, anon;
grant execute on function public.create_recipe_suggestion(uuid) to authenticated;

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
      cook_time_minutes, difficulty, instructions, image_url
    )
    values (
      uid, source_recipe.name, source_recipe.description, source_recipe.servings,
      source_recipe.prep_time_minutes, source_recipe.cook_time_minutes,
      source_recipe.difficulty, source_recipe.instructions, source_recipe.image_url
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

revoke all on function public.respond_to_recipe_suggestion(uuid, boolean) from public, anon;
grant execute on function public.respond_to_recipe_suggestion(uuid, boolean) to authenticated;
