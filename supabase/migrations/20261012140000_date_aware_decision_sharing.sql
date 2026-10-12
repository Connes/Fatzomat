-- Allow personal decisions for a selected future date to be shared and accepted
-- on that same date. The source plan ID is authoritative; the client snapshot
-- is checked against it to avoid sharing stale content.

drop function if exists public.send_decision_message(text,text,text,text,text,uuid,integer);
drop function if exists public.send_decision_message(text,text,text,text,text,uuid,integer,uuid);

create or replace function public.send_decision_message(
  p_message_type text,
  p_decision_type text default null,
  p_decision_value text default null,
  p_decision_name text default null,
  p_image_url text default null,
  p_recipe_id uuid default null,
  p_servings integer default null,
  p_source_plan_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  cid uuid;
  partner uuid;
  share_id uuid;
  sender_name text;
  source_plan public.personal_today_plans;
  decision_label text;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  if p_message_type not in ('ask','share') then raise exception 'Ungültiger Nachrichtentyp.'; end if;

  select connection_id into cid
  from public.connection_members where user_id = uid limit 1;
  if cid is null then raise exception 'Keine Verbindung zu einer zweiten Person vorhanden.'; end if;

  select user_id into partner
  from public.connection_members
  where connection_id = cid and user_id <> uid limit 1;
  if partner is null then raise exception 'Keine zweite Person ist verbunden.'; end if;

  select nullif(btrim(display_name), '') into sender_name
  from public.profiles where id = uid;

  if p_message_type = 'share' then
    if p_source_plan_id is null then raise exception 'Die ausgewählte Entscheidung konnte nicht gefunden werden. Bitte lade den Tag neu.'; end if;

    select * into source_plan
    from public.personal_today_plans
    where id = p_source_plan_id
      and user_id = uid
      and status = 'planned'
      and plan_date >= current_date
    for update;

    if source_plan.id is null then
      raise exception 'Deine Entscheidung hat sich geändert. Bitte lade den Tag neu.';
    end if;
    if source_plan.decision_type is distinct from p_decision_type
       or source_plan.decision_value is distinct from p_decision_value
       or source_plan.recipe_id is distinct from p_recipe_id then
      raise exception 'Deine Entscheidung hat sich geändert. Bitte lade den Tag neu.';
    end if;

    if exists (
      select 1 from public.decision_shares ds
      where ds.sender_id = uid
        and ds.source_plan_id = source_plan.id
        and ds.message_type = 'share'
        and ds.cancelled_at is null
    ) then
      raise exception 'Diese Tagesentscheidung wurde bereits geteilt. Sie kann nur einmal geteilt werden.';
    end if;

    if source_plan.decision_type not in ('recipe','order','dine_out','surprise') then
      raise exception 'Ungültige persönliche Entscheidung.';
    end if;

    decision_label := coalesce(nullif(btrim(p_decision_name), ''), nullif(btrim(p_decision_value), ''));
    if decision_label is null then raise exception 'Die ausgewählte Entscheidung konnte nicht gelesen werden.'; end if;
    if p_decision_type = 'recipe' and p_recipe_id is null then raise exception 'Die Rezeptentscheidung konnte nicht gelesen werden.'; end if;
    if p_decision_type <> 'recipe' and nullif(btrim(p_decision_value), '') is null then raise exception 'Die Auswahl konnte nicht gelesen werden.'; end if;

    insert into public.decision_shares(
      connection_id, sender_id, recipient_id, message_type, plan_date, source_plan_id,
      decision_type, decision_value, decision_name, image_url, recipe_id, servings
    ) values (
      cid, uid, partner, 'share', source_plan.plan_date, source_plan.id,
      p_decision_type, nullif(btrim(p_decision_value), ''), decision_label,
      nullif(btrim(p_image_url), ''), p_recipe_id, p_servings
    ) returning id into share_id;

    insert into public.app_notifications(user_id,type,title,body,decision_share_id)
    values (
      partner, 'decision_message', 'Entscheidung geteilt',
      coalesce(sender_name, 'Deine verbundene Person') || ' hat für ' ||
        to_char(source_plan.plan_date, 'DD.MM.YYYY') || ' „' || decision_label || '“ gewählt.',
      share_id
    );
  else
    insert into public.decision_shares(connection_id,sender_id,recipient_id,message_type,plan_date)
    values (cid,uid,partner,'ask',current_date) returning id into share_id;

    insert into public.app_notifications(user_id,type,title,body,decision_share_id)
    values (
      partner, 'decision_message', 'Entscheide Du',
      coalesce(sender_name, 'Deine verbundene Person') || ' möchte, dass du heute deine persönliche Essensentscheidung triffst.',
      share_id
    );
  end if;
  return share_id;
exception when unique_violation then
  raise exception 'Diese Tagesentscheidung wurde bereits geteilt. Sie kann nur einmal geteilt werden.';
end;
$$;

revoke all on function public.send_decision_message(text,text,text,text,text,uuid,integer,uuid) from public, anon;
grant execute on function public.send_decision_message(text,text,text,text,text,uuid,integer,uuid) to authenticated;

create or replace function public.accept_decision_share(p_share_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  share_row public.decision_shares;
  source_recipe public.recipes;
  personal_plan_id uuid;
  shared_plan_id uuid;
  sender_name text;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;

  select * into share_row
  from public.decision_shares
  where id = p_share_id
    and recipient_id = uid
    and public.is_connection_member(connection_id)
  for update;

  if share_row.id is null then raise exception 'Die geteilte Entscheidung ist nicht mehr verfügbar.'; end if;
  if share_row.message_type <> 'share' then raise exception 'Diese Nachricht enthält keine übernehmbare Entscheidung.'; end if;
  if share_row.cancelled_at is not null then raise exception 'Diese gemeinsame Entscheidung wurde bereits entfernt.'; end if;
  if share_row.plan_date < current_date then raise exception 'Der Tag dieser geteilten Entscheidung ist bereits vergangen.'; end if;
  if share_row.rejected_at is not null then raise exception 'Die geteilte Entscheidung wurde bereits abgelehnt.'; end if;

  if share_row.accepted_at is not null and share_row.accepted_plan_id is not null then
    return jsonb_build_object(
      'share_id', share_row.id, 'plan_id', share_row.accepted_plan_id,
      'decision_type', share_row.decision_type, 'recipe_id', share_row.accepted_recipe_id,
      'shared_recipe_plan_id', share_row.shared_recipe_plan_id
    );
  end if;

  if share_row.decision_type = 'recipe' then
    if share_row.recipe_id is null then raise exception 'Das geteilte Rezept ist nicht mehr verfügbar.'; end if;
    select * into source_recipe from public.recipes where id = share_row.recipe_id for share;
    if source_recipe.id is null then raise exception 'Das geteilte Rezept ist nicht mehr verfügbar.'; end if;

    personal_plan_id := public.set_personal_plan_for_date(
      share_row.plan_date, 'recipe', null, share_row.recipe_id, share_row.servings
    );

    select id into shared_plan_id
    from public.shared_recipe_plans
    where connection_id = share_row.connection_id
      and plan_date = share_row.plan_date
      and status <> 'cancelled'
    order by created_at desc limit 1;

    if shared_plan_id is null then
      insert into public.shared_recipe_plans(connection_id,recipe_id,shared_by,plan_date,status,servings)
      values (share_row.connection_id,share_row.recipe_id,share_row.sender_id,share_row.plan_date,'planned',share_row.servings)
      returning id into shared_plan_id;

      insert into public.shopping_items(shared_recipe_plan_id,food_id,name,quantity,unit,source)
      select shared_plan_id,ri.food_id,ri.name,
        round((ri.quantity * share_row.servings::numeric / greatest(source_recipe.servings,1))::numeric,2),
        ri.unit,'recipe'
      from public.recipe_ingredients ri where ri.recipe_id = share_row.recipe_id;
    end if;

    update public.decision_shares
    set accepted_at = now(), accepted_plan_id = personal_plan_id,
        accepted_recipe_id = share_row.recipe_id, shared_recipe_plan_id = shared_plan_id
    where id = share_row.id;
  elsif share_row.decision_type in ('order','dine_out','surprise') then
    if nullif(btrim(share_row.decision_value),'') is null then
      raise exception 'Die geteilte Entscheidung ist nicht mehr vollständig verfügbar.';
    end if;
    personal_plan_id := public.set_personal_plan_for_date(
      share_row.plan_date, share_row.decision_type, share_row.decision_value, null, null
    );
    update public.decision_shares set accepted_at = now(), accepted_plan_id = personal_plan_id
    where id = share_row.id;
  else
    raise exception 'Ungültige geteilte Entscheidung.';
  end if;

  select nullif(btrim(display_name),'') into sender_name from public.profiles where id = uid;
  insert into public.app_notifications(user_id,type,title,body,decision_share_id)
  values (
    share_row.sender_id, 'decision_message_response', 'Entscheidung übernommen',
    coalesce(sender_name,'Deine verbundene Person') || ' hat deine geteilte Entscheidung für ' ||
      to_char(share_row.plan_date, 'DD.MM.YYYY') || ' übernommen.',
    share_row.id
  );

  return jsonb_build_object(
    'share_id', share_row.id, 'plan_id', personal_plan_id,
    'decision_type', share_row.decision_type,
    'recipe_id', share_row.recipe_id, 'shared_recipe_plan_id', shared_plan_id
  );
end;
$$;

create or replace function public.reject_decision_share(p_share_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  changed integer := 0;
  recipient_name text;
  share_row public.decision_shares;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  if p_share_id is null then raise exception 'Keine Entscheidungs-ID vorhanden.'; end if;

  update public.decision_shares
  set rejected_at = now(), rejected_by = uid
  where id = p_share_id and recipient_id = uid and message_type = 'share'
    and plan_date >= current_date and accepted_at is null
    and cancelled_at is null and rejected_at is null;
  get diagnostics changed = row_count;
  if changed = 0 then raise exception 'Die geteilte Entscheidung ist nicht mehr offen.'; end if;

  select * into share_row from public.decision_shares where id = p_share_id;
  select nullif(btrim(display_name),'') into recipient_name from public.profiles where id = uid;
  insert into public.app_notifications(user_id,type,title,body,decision_share_id)
  values (
    share_row.sender_id, 'decision_message_response', 'Entscheidung abgelehnt',
    coalesce(recipient_name,'Deine verbundene Person') || ' hat deine geteilte Entscheidung für ' ||
      to_char(share_row.plan_date, 'DD.MM.YYYY') || ' abgelehnt.',
    share_row.id
  );
  return true;
end;
$$;

revoke all on function public.accept_decision_share(uuid) from public, anon;
grant execute on function public.accept_decision_share(uuid) to authenticated;
revoke all on function public.reject_decision_share(uuid) from public, anon;
grant execute on function public.reject_decision_share(uuid) to authenticated;

notify pgrst, 'reload schema';
