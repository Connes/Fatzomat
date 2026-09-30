-- Technical audit 3: serialize concurrent joins for the same connection.
-- The connection row lock makes the member-count check and subsequent insert
-- atomic with respect to other join_connection calls targeting that code.
create or replace function public.join_connection(p_code text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  cid uuid;
  member_count integer;
begin
  if p_code is null or length(trim(p_code)) < 4 then
    raise exception 'Ungültiger Verbindungscode.';
  end if;

  if exists (
    select 1
    from public.connection_members
    where user_id = auth.uid()
  ) then
    raise exception 'Dieses Gerät ist bereits mit einer Person verbunden.';
  end if;

  select id
    into cid
  from public.connections
  where code = upper(trim(p_code))
  for update;

  if cid is null then
    raise exception 'Verbindungscode nicht gefunden.';
  end if;

  select count(*)
    into member_count
  from public.connection_members
  where connection_id = cid;

  if member_count >= 2 then
    raise exception 'Diese Verbindung ist bereits vollständig.';
  end if;

  insert into public.connection_members(connection_id, user_id)
  values (cid, auth.uid());

  return true;
end;
$$;

revoke all on function public.join_connection(text) from public, anon;
grant execute on function public.join_connection(text) to authenticated;
