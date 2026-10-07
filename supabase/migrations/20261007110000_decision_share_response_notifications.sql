-- Notify the sender when the recipient accepts or rejects a shared decision.
-- The response is durable in app_notifications and therefore also reaches the
-- existing push-notification webhook.

create or replace function public.accept_decision_share(p_share_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  uid uuid := auth.uid();
  share_row public.decision_shares;
  source_recipe public.recipes;
  copied_recipe_id uuid;
  personal_plan_id uuid;
  shared_plan_id uuid;
  sender_name text;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;

  select * into share_row
  from public.decision_shares
  where id = p_share_id and recipient_id = uid and public.is_connection_member(connection_id)
  for update;

  if share_row.id is null then raise exception 'Die geteilte Entscheidung ist nicht mehr verfügbar.'; end if;
  if share_row.message_type <> 'share' then raise exception 'Diese Nachricht enthält keine übernehmbare Entscheidung.'; end if;
  if share_row.cancelled_at is not null then raise exception 'Diese gemeinsame Entscheidung wurde bereits entfernt.'; end if;
  if share_row.plan_date <> current_date then raise exception 'Die geteilte Entscheidung gilt nicht mehr für heute.'; end if;
  if share_row.rejected_at is not null then raise exception 'Die geteilte Entscheidung wurde bereits abgelehnt.'; end if;

  if share_row.accepted_at is not null and share_row.accepted_plan_id is not null then
    return jsonb_build_object(
      'share_id', share_row.id,
      'plan_id', share_row.accepted_plan_id,
      'decision_type', share_row.decision_type,
      'recipe_id', share_row.accepted_recipe_id,
      'shared_recipe_plan_id', share_row.shared_recipe_plan_id
    );
  end if;

  if share_row.decision_type = 'recipe' then
    if share_row.recipe_id is null then raise exception 'Das geteilte Rezept ist nicht mehr verfügbar.'; end if;

    copied_recipe_id := share_row.accepted_recipe_id;
    if copied_recipe_id is null then
      select * into source_recipe
      from public.recipes
      where id = share_row.recipe_id and created_by = share_row.sender_id
      for share;

      if source_recipe.id is null then raise exception 'Das geteilte Rezept ist nicht mehr verfügbar.'; end if;

      insert into public.recipes(
        created_by,name,description,servings,prep_time_minutes,cook_time_minutes,
        difficulty,instructions,image_url
      )
      values(
        uid,source_recipe.name,source_recipe.description,source_recipe.servings,
        source_recipe.prep_time_minutes,source_recipe.cook_time_minutes,
        source_recipe.difficulty,source_recipe.instructions,source_recipe.image_url
      )
      returning id into copied_recipe_id;

      insert into public.recipe_ingredients(
        recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative
      )
      select copied_recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative
      from public.recipe_ingredients
      where recipe_id = share_row.recipe_id;

      insert into public.recipe_saves(recipe_id,user_id)
      values(copied_recipe_id,uid)
      on conflict(recipe_id,user_id) do nothing;
    end if;

    personal_plan_id := public.set_personal_today_plan(copied_recipe_id,share_row.servings);

    select id into shared_plan_id
    from public.shared_recipe_plans
    where connection_id = share_row.connection_id
      and plan_date = current_date
      and status <> 'cancelled'
    order by created_at desc
    limit 1;

    if shared_plan_id is null then
      insert into public.shared_recipe_plans(
        connection_id,recipe_id,shared_by,plan_date,status,servings
      )
      values(
        share_row.connection_id,
        share_row.recipe_id,
        share_row.sender_id,
        current_date,
        'planned',
        share_row.servings
      )
      returning id into shared_plan_id;

      insert into public.shopping_items(
        shared_recipe_plan_id,food_id,name,quantity,unit,source
      )
      select
        shared_plan_id,
        ri.food_id,
        ri.name,
        round((ri.quantity * share_row.servings::numeric / greatest(source_recipe.servings,1))::numeric,2),
        ri.unit,
        'recipe'
      from public.recipe_ingredients ri
      where ri.recipe_id = share_row.recipe_id;
    end if;

    update public.decision_shares
    set accepted_at = now(),
        accepted_plan_id = personal_plan_id,
        shared_recipe_plan_id = shared_plan_id
    where id = share_row.id;
  elsif share_row.decision_type in ('order','dine_out','surprise') then
    if nullif(btrim(share_row.decision_value),'') is null then
      raise exception 'Die geteilte Entscheidung ist nicht mehr vollständig verfügbar.';
    end if;

    personal_plan_id := public.set_personal_today_decision(
      share_row.decision_type, share_row.decision_value
    );

    update public.decision_shares
    set accepted_at = now(), accepted_plan_id = personal_plan_id
    where id = share_row.id;
  else
    raise exception 'Ungültige geteilte Entscheidung.';
  end if;

  select nullif(btrim(display_name),'')
  into sender_name
  from public.profiles
  where id = uid;

  insert into public.app_notifications(user_id,type,title,body,decision_share_id)
  values (
    share_row.sender_id,
    'decision_message_response',
    'Entscheidung übernommen',
    coalesce(sender_name,'Deine verbundene Person') || ' hat deine geteilte Entscheidung übernommen.',
    share_row.id
  );

  return jsonb_build_object(
    'share_id', share_row.id,
    'plan_id', personal_plan_id,
    'decision_type', share_row.decision_type,
    'recipe_id', copied_recipe_id,
    'shared_recipe_plan_id', shared_plan_id
  );
end;
$function$;

revoke execute on function public.accept_decision_share(uuid) from public, anon;
grant execute on function public.accept_decision_share(uuid) to authenticated;

create or replace function public.reject_decision_share(p_share_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  uid uuid := auth.uid();
  changed integer := 0;
  recipient_name text;
  share_row public.decision_shares;
begin
  if uid is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  if p_share_id is null then
    raise exception 'Keine Entscheidungs-ID vorhanden.';
  end if;

  update public.decision_shares
  set rejected_at = now(),
      rejected_by = uid
  where id = p_share_id
    and recipient_id = uid
    and message_type = 'share'
    and plan_date = current_date
    and accepted_at is null
    and cancelled_at is null
    and rejected_at is null;

  get diagnostics changed = row_count;

  if changed = 0 then
    raise exception 'Die geteilte Entscheidung ist nicht mehr offen.';
  end if;

  select * into share_row
  from public.decision_shares
  where id = p_share_id;

  select nullif(btrim(display_name),'')
  into recipient_name
  from public.profiles
  where id = uid;

  insert into public.app_notifications(user_id,type,title,body,decision_share_id)
  values (
    share_row.sender_id,
    'decision_message_response',
    'Entscheidung abgelehnt',
    coalesce(recipient_name,'Deine verbundene Person') || ' hat deine geteilte Entscheidung abgelehnt.',
    share_row.id
  );

  return true;
end;
$function$;

revoke execute on function public.reject_decision_share(uuid) from public, anon;
grant execute on function public.reject_decision_share(uuid) to authenticated;
