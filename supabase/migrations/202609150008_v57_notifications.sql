-- V57 / Part 4: in-app notifications for the decision handoff.
-- Push delivery remains provider-dependent. The app now has a realtime inbox
-- so the collaboration flow is useful without requiring FCM/APNs credentials.

alter table public.app_notifications
  add column if not exists decision_request_id uuid
  references public.decision_requests(id) on delete cascade;

create index if not exists idx_notifications_user_unread
  on public.app_notifications(user_id, created_at desc)
  where read_at is null;

-- Realtime delivery for the notification inbox.
alter publication supabase_realtime add table public.app_notifications;

create or replace function public.create_decision_request(p_assigned_to uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  cid uuid;
  request_row public.decision_requests;
  sender_name text;
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

  if p_assigned_to is null or p_assigned_to = uid
     or not public.is_connection_member(cid, p_assigned_to) then
    raise exception 'Die ausgewählte Person gehört nicht zur Verbindung.';
  end if;

  if exists (
    select 1 from public.decision_requests dr
    where dr.connection_id = cid and dr.status = 'pending'
  ) then
    raise exception 'Für eure Verbindung läuft bereits eine Entscheidung.';
  end if;

  insert into public.decision_requests(connection_id, created_by, assigned_to)
  values (cid, uid, p_assigned_to)
  returning * into request_row;

  select nullif(btrim(p.display_name), '') into sender_name
  from public.profiles p
  where p.id = uid;

  insert into public.app_notifications(
    user_id, type, title, body, decision_request_id
  ) values (
    p_assigned_to,
    'decision_request',
    'Du entscheidest heute',
    coalesce(sender_name, 'Deine Verbindung') || ' hat dir die Entscheidung für heute übergeben.',
    request_row.id
  );

  return jsonb_build_object(
    'id', request_row.id,
    'connection_id', request_row.connection_id,
    'created_by', request_row.created_by,
    'assigned_to', request_row.assigned_to,
    'status', request_row.status,
    'decision_mode', request_row.decision_mode,
    'result_type', request_row.result_type,
    'result_id', request_row.result_id,
    'created_at', request_row.created_at,
    'resolved_at', request_row.resolved_at
  );
end;
$$;

revoke all on function public.create_decision_request(uuid) from public, anon;
grant execute on function public.create_decision_request(uuid) to authenticated;

create or replace function public.accept_decision_request(p_request_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  changed integer;
  request_row public.decision_requests;
  accepter_name text;
begin
  select * into request_row
  from public.decision_requests
  where id = p_request_id
    and assigned_to = auth.uid()
    and status = 'pending'
  for update;

  if request_row.id is null then
    return false;
  end if;

  update public.decision_requests
  set status = 'accepted'
  where id = p_request_id;
  get diagnostics changed = row_count;

  if changed = 1 then
    select nullif(btrim(p.display_name), '') into accepter_name
    from public.profiles p
    where p.id = auth.uid();

    insert into public.app_notifications(user_id, type, title, body, decision_request_id)
    values (
      request_row.created_by,
      'decision_request_accepted',
      'Entscheidung angenommen',
      coalesce(accepter_name, 'Deine Verbindung') || ' entscheidet jetzt, was ihr heute esst.',
      request_row.id
    );
  end if;

  return changed = 1;
end;
$$;

revoke all on function public.accept_decision_request(uuid) from public, anon;
grant execute on function public.accept_decision_request(uuid) to authenticated;
