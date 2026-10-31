-- Track confirmed permanent push-delivery failures for both decision messages
-- ("Entscheide Du") and shared daily decisions. Temporary FCM errors and users
-- without registered devices are deliberately not counted.
create table if not exists public.decision_delivery_state (
  connection_id uuid not null,
  sender_id uuid not null,
  recipient_id uuid not null,
  consecutive_failures integer not null default 0 check (consecutive_failures >= 0),
  last_notification_id uuid,
  updated_at timestamptz not null default now(),
  primary key (connection_id, sender_id, recipient_id)
);

create table if not exists public.decision_delivery_events (
  notification_id uuid primary key,
  connection_id uuid not null,
  sender_id uuid not null,
  recipient_id uuid not null,
  created_at timestamptz not null default now()
);

alter table public.decision_delivery_state enable row level security;
alter table public.decision_delivery_events enable row level security;
revoke all on public.decision_delivery_state from public, anon, authenticated;
revoke all on public.decision_delivery_events from public, anon, authenticated;

create or replace function public.record_decision_push_delivery(
  p_notification_id uuid,
  p_permanent_failure boolean
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  notification_row public.app_notifications%rowtype;
  share_row public.decision_shares%rowtype;
  failure_count integer;
  event_result text := 'ignored';
begin
  if p_notification_id is null then
    return 'ignored';
  end if;

  select * into notification_row
  from public.app_notifications
  where id = p_notification_id;

  if not found
     or notification_row.type <> 'decision_message'
     or notification_row.decision_share_id is null then
    return 'ignored';
  end if;

  select * into share_row
  from public.decision_shares
  where id = notification_row.decision_share_id;

  if not found
     or share_row.recipient_id <> notification_row.user_id then
    return 'ignored';
  end if;

  -- Serialize attempts for this sender/recipient pair and make webhook retries
  -- idempotent. A successful push resets the consecutive failure counter.
  perform pg_advisory_xact_lock(hashtextextended(
    share_row.connection_id::text || ':' ||
    share_row.sender_id::text || ':' ||
    share_row.recipient_id::text, 0
  ));

  if not p_permanent_failure then
    insert into public.decision_delivery_state (
      connection_id, sender_id, recipient_id,
      consecutive_failures, last_notification_id, updated_at
    ) values (
      share_row.connection_id, share_row.sender_id, share_row.recipient_id,
      0, p_notification_id, now()
    )
    on conflict (connection_id, sender_id, recipient_id) do update
      set consecutive_failures = 0,
          last_notification_id = excluded.last_notification_id,
          updated_at = now();
    return 'delivered';
  end if;

  -- Each notification may only contribute one failure, even if webhook
  -- retries arrive after a newer notification has already been processed.
  insert into public.decision_delivery_events (
    notification_id, connection_id, sender_id, recipient_id
  ) values (
    p_notification_id, share_row.connection_id, share_row.sender_id, share_row.recipient_id
  ) on conflict (notification_id) do nothing;
  if not found then
    return 'duplicate';
  end if;

  insert into public.decision_delivery_state (
    connection_id, sender_id, recipient_id,
    consecutive_failures, last_notification_id, updated_at
  ) values (
    share_row.connection_id, share_row.sender_id, share_row.recipient_id,
    1, p_notification_id, now()
  )
  on conflict (connection_id, sender_id, recipient_id) do update
    set consecutive_failures = public.decision_delivery_state.consecutive_failures + 1,
        last_notification_id = excluded.last_notification_id,
        updated_at = now()
  returning consecutive_failures into failure_count;

  if failure_count = 1 then
    insert into public.app_notifications(user_id, type, title, body)
    values (
      share_row.sender_id,
      'delivery_failed',
      'Nachricht nicht zugestellt',
      'Deine Nachricht konnte nicht zugestellt werden. Wenn auch die nächste Nachricht scheitert, wird eure Verbindung getrennt.'
    );
    event_result := 'first_failure';
  else
    -- Save a sender-facing notification without a decision_share_id first,
    -- because deleting the connection cascades the shared message records.
    insert into public.app_notifications(user_id, type, title, body)
    values (
      share_row.sender_id,
      'connection_delivery_failed',
      'Verbindung getrennt',
      'Zwei Nachrichten konnten nicht zugestellt werden. Eure Verbindung wurde deshalb aufgelöst.'
    );

    delete from public.connections c
    where c.id = share_row.connection_id;

    delete from public.decision_delivery_state s
    where s.connection_id = share_row.connection_id;

    event_result := 'connection_disconnected';
  end if;

  return event_result;
end;
$$;

revoke all on function public.record_decision_push_delivery(uuid, boolean) from public, anon, authenticated;
grant execute on function public.record_decision_push_delivery(uuid, boolean) to service_role;
