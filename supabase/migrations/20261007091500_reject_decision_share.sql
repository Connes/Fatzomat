-- Incoming shared decisions can be explicitly rejected without deleting
-- the durable collaboration message.
alter table public.decision_shares
  add column if not exists rejected_at timestamptz,
  add column if not exists rejected_by uuid references auth.users(id) on delete set null;

create index if not exists decision_shares_rejected_by_idx
  on public.decision_shares (rejected_by)
  where rejected_by is not null;

create or replace function public.reject_decision_share(p_share_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  changed integer := 0;
begin
  if uid is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  if p_share_id is null then
    raise exception 'Keine Entscheidungs-ID vorhanden.';
  end if;

  update public.decision_shares
  set rejected_at = now(),
      rejected_by = uid
  where id = p_share_id
    and recipient_id = uid
    and message_type = 'share'
    and plan_date = current_date
    and accepted_at is null
    and cancelled_at is null
    and rejected_at is null;

  get diagnostics changed = row_count;

  if changed = 0 then
    raise exception 'Die geteilte Entscheidung ist nicht mehr offen.';
  end if;

  return true;
end;
$$;

revoke execute on function public.reject_decision_share(uuid) from public, anon;
grant execute on function public.reject_decision_share(uuid) to authenticated;
