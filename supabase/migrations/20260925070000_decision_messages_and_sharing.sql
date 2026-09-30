-- V85: "Entscheide Du" is a message, not a decision-request lifecycle.
-- Personal decisions stay on personal_today_plans. This table only stores
-- durable collaboration messages and, for shared decisions, a snapshot of
-- what was shared at send time.

create table if not exists public.decision_shares (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references public.connections(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  message_type text not null check (message_type in ('ask','share')),
  plan_date date not null default current_date,
  decision_type text,
  decision_value text,
  decision_name text,
  image_url text,
  recipe_id uuid references public.recipes(id) on delete set null,
  servings integer,
  created_at timestamptz not null default now(),
  check (sender_id <> recipient_id),
  check (message_type = 'ask' or decision_type is not null),
  check (message_type = 'ask' or coalesce(nullif(btrim(decision_name), ''), nullif(btrim(decision_value), '')) is not null)
);

create index if not exists idx_decision_shares_recipient_created
  on public.decision_shares(recipient_id, created_at desc);
create index if not exists idx_decision_shares_sender_created
  on public.decision_shares(sender_id, created_at desc);

grant select on public.decision_shares to authenticated;

alter table public.decision_shares enable row level security;

drop policy if exists "decision shares members read" on public.decision_shares;
create policy "decision shares members read"
on public.decision_shares for select to authenticated
using (
  public.is_connection_member(connection_id)
  and (sender_id = (select auth.uid()) or recipient_id = (select auth.uid()))
);

alter table public.app_notifications
  add column if not exists decision_share_id uuid
  references public.decision_shares(id) on delete cascade;

create index if not exists idx_notifications_decision_share_id
  on public.app_notifications(decision_share_id);

create or replace function public.send_decision_message(p_message_type text)
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
  current_plan record;
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
    select
      p.id,
      p.plan_date,
      p.decision_type,
      p.decision_value,
      p.servings,
      p.recipe_id,
      r.name as recipe_name,
      r.image_url as recipe_image_url
    into current_plan
    from public.personal_today_plans p
    left join public.recipes r on r.id = p.recipe_id
    where p.user_id = uid
      and p.plan_date = current_date
      and p.status <> 'cancelled'
    order by p.updated_at desc nulls last
    limit 1;

    if not found then
      raise exception 'Du hast für heute noch keine persönliche Entscheidung getroffen.';
    end if;

    decision_label := case
      when current_plan.decision_type = 'recipe' then current_plan.recipe_name
      else current_plan.decision_value
    end;

    if coalesce(nullif(btrim(decision_label), ''), '') = '' then
      raise exception 'Deine heutige Entscheidung konnte nicht gelesen werden.';
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
    case when p_message_type = 'share' then current_plan.decision_type else null end,
    case when p_message_type = 'share' then current_plan.decision_value else null end,
    case when p_message_type = 'share' then decision_label else null end,
    case when p_message_type = 'share' then current_plan.recipe_image_url else null end,
    case when p_message_type = 'share' then current_plan.recipe_id else null end,
    case when p_message_type = 'share' then current_plan.servings else null end
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

revoke all on function public.send_decision_message(text) from public, anon;
grant execute on function public.send_decision_message(text) to authenticated;

-- Notification realtime is already the canonical inbox channel. The new
-- decision message therefore needs no second realtime system.
