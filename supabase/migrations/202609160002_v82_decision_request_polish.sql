-- V82: make the decision handoff lifecycle visible and recoverable.
-- Cancelling an active request also informs the person who received it.

create or replace function public.cancel_decision_request(p_request_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  changed integer;
  request_row public.decision_requests;
  sender_name text;
begin
  select * into request_row
  from public.decision_requests
  where id = p_request_id
    and created_by = auth.uid()
    and status in ('pending', 'accepted')
  for update;

  if request_row.id is null then
    return false;
  end if;

  update public.decision_requests
  set status = 'cancelled', resolved_at = now()
  where id = p_request_id;
  get diagnostics changed = row_count;

  if changed = 1 then
    select nullif(btrim(p.display_name), '') into sender_name
    from public.profiles p
    where p.id = auth.uid();

    insert into public.app_notifications(user_id, type, title, body, decision_request_id)
    values (
      request_row.assigned_to,
      'decision_request_cancelled',
      'Entscheidungsanfrage zurückgenommen',
      coalesce(sender_name, 'Deine Verbindung') || ' hat die Entscheidung für heute zurückgenommen.',
      request_row.id
    );
  end if;

  return changed = 1;
end;
$$;

revoke all on function public.cancel_decision_request(uuid) from public, anon;
grant execute on function public.cancel_decision_request(uuid) to authenticated;
