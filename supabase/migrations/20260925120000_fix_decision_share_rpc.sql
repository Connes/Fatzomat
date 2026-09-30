-- V85.1: Make sharing the personal Today decision independent from a second
-- read of personal_today_plans. The Today page already has the exact snapshot
-- the user is looking at, so the RPC receives that snapshot directly.
-- This also avoids failures when the plan's recipe relation is temporarily
-- unavailable while the personal decision itself is still valid.

drop function if exists public.send_decision_message(text);
drop function if exists public.send_decision_message(text,text,text,text,text,uuid,integer);

create or replace function public.send_decision_message(
  p_message_type text,
  p_decision_type text default null,
  p_decision_value text default null,
  p_decision_name text default null,
  p_image_url text default null,
  p_recipe_id uuid default null,
  p_servings integer default null
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
  decision_label text;
begin
  if uid is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  if p_message_type not in ('ask','share') then
    raise exception 'Ungültiger Nachrichtentyp.';
  end if;

  select cm.connection_id into cid
  from public.connection_members cm
  where cm.user_id = uid
  limit 1;

  if cid is null then
    raise exception 'Keine Verbindung zu einer zweiten Person vorhanden.';
  end if;

  select cm.user_id into partner
  from public.connection_members cm
  where cm.connection_id = cid
    and cm.user_id <> uid
  limit 1;

  if partner is null then
    raise exception 'Keine zweite Person ist verbunden.';
  end if;

  select nullif(btrim(p.display_name), '') into sender_name
  from public.profiles p
  where p.id = uid;

  if p_message_type = 'share' then
    if p_decision_type not in ('recipe','order','dine_out','surprise') then
      raise exception 'Ungültige persönliche Entscheidung.';
    end if;

    decision_label := coalesce(nullif(btrim(p_decision_name), ''), nullif(btrim(p_decision_value), ''));
    if decision_label is null then
      raise exception 'Deine heutige Entscheidung konnte nicht gelesen werden.';
    end if;

    if p_decision_type = 'recipe' and p_recipe_id is null then
      raise exception 'Die Rezeptentscheidung konnte nicht gelesen werden.';
    end if;

    if p_decision_type <> 'recipe' and nullif(btrim(p_decision_value), '') is null then
      raise exception 'Die heutige Auswahl konnte nicht gelesen werden.';
    end if;
  end if;

  insert into public.decision_shares(
    connection_id,
    sender_id,
    recipient_id,
    message_type,
    plan_date,
    decision_type,
    decision_value,
    decision_name,
    image_url,
    recipe_id,
    servings
  )
  values (
    cid,
    uid,
    partner,
    p_message_type,
    current_date,
    case when p_message_type = 'share' then p_decision_type else null end,
    case when p_message_type = 'share' then nullif(btrim(p_decision_value), '') else null end,
    case when p_message_type = 'share' then decision_label else null end,
    case when p_message_type = 'share' then nullif(btrim(p_image_url), '') else null end,
    case when p_message_type = 'share' then p_recipe_id else null end,
    case when p_message_type = 'share' then p_servings else null end
  )
  returning id into share_id;

  if p_message_type = 'ask' then
    insert into public.app_notifications(user_id, type, title, body, decision_share_id)
    values (
      partner,
      'decision_message',
      'Entscheide Du',
      coalesce(sender_name, 'Deine verbundene Person') || ' möchte, dass du heute deine persönliche Essensentscheidung triffst.',
      share_id
    );
  else
    insert into public.app_notifications(user_id, type, title, body, decision_share_id)
    values (
      partner,
      'decision_message',
      'Entscheidung geteilt',
      coalesce(sender_name, 'Deine verbundene Person') || ' hat heute „' || decision_label || '“ gewählt.',
      share_id
    );
  end if;

  return share_id;
end;
$$;

revoke all on function public.send_decision_message(text,text,text,text,text,uuid,integer) from public, anon;
grant execute on function public.send_decision_message(text,text,text,text,text,uuid,integer) to authenticated;
