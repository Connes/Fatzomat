-- Preserve the date selected on TodayPage when sending "Entscheide Du".
-- The date is stored with the durable share row and is reflected in the push text.

drop function if exists public.send_decision_message(text);
drop function if exists public.send_decision_message(text,text,text,text,text,uuid,integer,uuid);

create or replace function public.send_decision_message(
  p_message_type text,
  p_decision_type text default null,
  p_decision_value text default null,
  p_decision_name text default null,
  p_image_url text default null,
  p_recipe_id uuid default null,
  p_servings integer default null,
  p_source_plan_id uuid default null,
  p_plan_date date default current_date
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
    if p_plan_date is null then raise exception 'Bitte wähle ein Datum für die Entscheidung.'; end if;
    if p_plan_date < current_date then raise exception 'Für vergangene Tage kann keine neue Entscheidung angefragt werden.'; end if;

    insert into public.decision_shares(connection_id,sender_id,recipient_id,message_type,plan_date)
    values (cid,uid,partner,'ask',p_plan_date) returning id into share_id;

    insert into public.app_notifications(user_id,type,title,body,decision_share_id)
    values (
      partner, 'decision_message', 'Entscheide Du',
      coalesce(sender_name, 'Deine verbundene Person') || ' möchte, dass du für ' ||
        to_char(p_plan_date, 'DD.MM.YYYY') || ' deine persönliche Essensentscheidung triffst.',
      share_id
    );
  end if;
  return share_id;
exception when unique_violation then
  raise exception 'Diese Tagesentscheidung wurde bereits geteilt. Sie kann nur einmal geteilt werden.';
end;
$$;

revoke all on function public.send_decision_message(text,text,text,text,text,uuid,integer,uuid,date) from public, anon;
grant execute on function public.send_decision_message(text,text,text,text,text,uuid,integer,uuid,date) to authenticated;

notify pgrst, 'reload schema';
