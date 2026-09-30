-- V57 / Part 2: safe participant actions for decision requests.

-- State changes happen only through the RPCs below. This keeps clients from
-- changing decision results or statuses directly.
drop policy if exists "decision requests participants update" on public.decision_requests;

create or replace function public.accept_decision_request(p_request_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  changed integer;
begin
  update public.decision_requests
  set status = 'accepted'
  where id = p_request_id
    and assigned_to = auth.uid()
    and status = 'pending';
  get diagnostics changed = row_count;
  return changed = 1;
end;
$$;

revoke all on function public.accept_decision_request(uuid) from public, anon;
grant execute on function public.accept_decision_request(uuid) to authenticated;

create or replace function public.resolve_decision_request(
  p_request_id uuid,
  p_decision_mode text,
  p_result_type text,
  p_result_id text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  changed integer;
begin
  if p_decision_mode is null or p_result_type is null or p_result_id is null or btrim(p_result_id) = '' then
    raise exception 'Eine vollständige Entscheidung ist erforderlich.';
  end if;

  update public.decision_requests
  set status = 'resolved',
      decision_mode = p_decision_mode,
      result_type = p_result_type,
      result_id = p_result_id,
      resolved_at = now()
  where id = p_request_id
    and assigned_to = auth.uid()
    and status in ('pending', 'accepted');

  get diagnostics changed = row_count;
  if changed <> 1 then
    raise exception 'Die Entscheidungsanfrage ist nicht mehr offen.';
  end if;
  return true;
end;
$$;

revoke all on function public.resolve_decision_request(uuid,text,text,text) from public, anon;
grant execute on function public.resolve_decision_request(uuid,text,text,text) to authenticated;

create or replace function public.cancel_decision_request(p_request_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  changed integer;
begin
  update public.decision_requests
  set status = 'cancelled', resolved_at = now()
  where id = p_request_id
    and created_by = auth.uid()
    and status in ('pending', 'accepted');
  get diagnostics changed = row_count;
  return changed = 1;
end;
$$;

revoke all on function public.cancel_decision_request(uuid) from public, anon;
grant execute on function public.cancel_decision_request(uuid) to authenticated;
