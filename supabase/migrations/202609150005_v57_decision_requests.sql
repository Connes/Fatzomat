-- V57 / Part 1: structured two-person decision requests.
-- This is intentionally not a chat/message system. A request has one sender,
-- one recipient and one eventual decision result.

create table if not exists public.decision_requests (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references public.connections(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  assigned_to uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending','accepted','resolved','cancelled','expired')),
  decision_mode text,
  result_type text,
  result_id text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  check (created_by <> assigned_to)
);

create index if not exists idx_decision_requests_assigned_status
  on public.decision_requests(assigned_to, status, created_at desc);
create index if not exists idx_decision_requests_created_status
  on public.decision_requests(created_by, status, created_at desc);
create index if not exists idx_decision_requests_connection_status
  on public.decision_requests(connection_id, status, created_at desc);

create unique index if not exists decision_requests_one_pending_per_connection
  on public.decision_requests(connection_id)
  where status = 'pending';

alter table public.decision_requests enable row level security;

create policy "decision requests connection members can read"
on public.decision_requests for select to authenticated
using (public.is_connection_member(connection_id));

create policy "decision requests sender insert"
on public.decision_requests for insert to authenticated
with check (
  created_by = (select auth.uid())
  and public.is_connection_member(connection_id)
  and public.is_connection_member(connection_id, assigned_to)
  and assigned_to <> (select auth.uid())
);

create policy "decision requests participants update"
on public.decision_requests for update to authenticated
using (
  public.is_connection_member(connection_id)
  and (created_by = (select auth.uid()) or assigned_to = (select auth.uid()))
)
with check (
  public.is_connection_member(connection_id)
  and (created_by = (select auth.uid()) or assigned_to = (select auth.uid()))
);

create policy "decision requests sender delete"
on public.decision_requests for delete to authenticated
using (created_by = (select auth.uid()));

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

alter publication supabase_realtime add table public.decision_requests;
