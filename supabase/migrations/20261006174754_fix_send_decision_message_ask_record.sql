-- Fix the ask path of send_decision_message.
-- PL/pgSQL record fields cannot be referenced before the record has been
-- assigned. The previous implementation referenced current_plan.id inside
-- a CASE expression even for message_type='ask', causing:
-- "record \"current_plan\" is not assigned yet".
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
set search_path to 'public', 'pg_temp'
as $function$
declare
  uid uuid := auth.uid();
  cid uuid;
  partner uuid;
  share_id uuid;
  sender_name text;
  current_plan record;
  decision_label text;
begin
  if uid is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  if p_message_type not in ('ask','share') then
    raise exception 'Ungültiger Nachrichtentyp.';
  end if;

  select connection_id into cid
  from public.connection_members
  where user_id = uid
  limit 1;

  if cid is null then
    raise exception 'Keine Verbindung zu einer zweiten Person vorhanden.';
  end if;

  select user_id into partner
  from public.connection_members
  where connection_id = cid
    and user_id <> uid
  limit 1;

  if partner is null then
    raise exception 'Keine zweite Person ist verbunden.';
  end if;

  select nullif(btrim(display_name),'')
    into sender_name
  from public.profiles
  where id = uid;

  if p_message_type = 'share' then
    select p.id,p.plan_date,p.decision_type,p.decision_value,p.servings
      into current_plan
    from public.personal_today_plans p
    where p.user_id=uid
      and p.plan_date=current_date
      and p.status<>'cancelled'
    order by p.updated_at desc nulls last
    limit 1;

    if not found then
      raise exception 'Du hast für heute noch keine persönliche Entscheidung getroffen.';
    end if;

    if exists (
      select 1
      from public.decision_shares ds
      where ds.sender_id=uid
        and ds.source_plan_id=current_plan.id
        and ds.message_type='share'
        and ds.cancelled_at is null
    ) then
      raise exception 'Diese Tagesentscheidung wurde bereits geteilt. Sie kann nur einmal geteilt werden.';
    end if;

    if current_plan.decision_type<>p_decision_type then
      raise exception 'Deine heutige Entscheidung hat sich geändert. Bitte öffne Heute neu.';
    end if;

    decision_label:=coalesce(
      nullif(btrim(p_decision_name),''),
      nullif(btrim(p_decision_value),'')
    );

    if decision_label is null then
      raise exception 'Deine heutige Entscheidung konnte nicht gelesen werden.';
    end if;

    if p_decision_type='recipe' and p_recipe_id is null then
      raise exception 'Die Rezeptentscheidung konnte nicht gelesen werden.';
    end if;

    if p_decision_type<>'recipe'
       and nullif(btrim(p_decision_value),'') is null then
      raise exception 'Die heutige Auswahl konnte nicht gelesen werden.';
    end if;

    insert into public.decision_shares(
      connection_id,sender_id,recipient_id,message_type,plan_date,source_plan_id,
      decision_type,decision_value,decision_name,image_url,recipe_id,servings
    )
    values (
      cid,uid,partner,p_message_type,current_date,current_plan.id,
      p_decision_type,nullif(btrim(p_decision_value),''),
      decision_label,nullif(btrim(p_image_url),''),
      p_recipe_id,p_servings
    )
    returning id into share_id;
  else
    insert into public.decision_shares(
      connection_id,sender_id,recipient_id,message_type,plan_date
    )
    values (
      cid,uid,partner,'ask',current_date
    )
    returning id into share_id;
  end if;

  insert into public.app_notifications(user_id,type,title,body,decision_share_id)
  values (
    partner,
    'decision_message',
    case when p_message_type='share' then 'Entscheidung geteilt' else 'Entscheide Du' end,
    case when p_message_type='share'
      then coalesce(sender_name,'Deine verbundene Person') || ' hat heute „' || decision_label || '“ gewählt.'
      else coalesce(sender_name,'Deine verbundene Person') || ' möchte, dass du heute deine persönliche Essensentscheidung triffst.'
    end,
    share_id
  );

  return share_id;

exception when unique_violation then
  raise exception 'Diese Tagesentscheidung wurde bereits geteilt. Sie kann nur einmal geteilt werden.';
end;
$function$;
