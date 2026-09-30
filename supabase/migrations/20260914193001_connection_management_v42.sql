-- v42: connection status and safe disconnect.

create or replace function public.connection_info()
returns table(connection_id uuid, connection_code text, member_count integer)
language sql
security definer
set search_path = public
stable
as $$
  select c.id, c.code, count(cm.user_id)::integer
  from public.connections c
  join public.connection_members mine
    on mine.connection_id = c.id
   and mine.user_id = auth.uid()
  join public.connection_members cm
    on cm.connection_id = c.id
  group by c.id, c.code;
$$;

revoke all on function public.connection_info() from public, anon;
grant execute on function public.connection_info() to authenticated;

create or replace function public.disconnect_connection()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  cid uuid;
  remaining integer;
begin
  if auth.uid() is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  select connection_id into cid
  from public.connection_members
  where user_id = auth.uid()
  limit 1;

  if cid is null then
    return false;
  end if;

  delete from public.connection_members
  where connection_id = cid
    and user_id = auth.uid();

  select count(*) into remaining
  from public.connection_members
  where connection_id = cid;

  if remaining = 0 then
    delete from public.connections where id = cid;
  end if;

  return true;
end;
$$;

revoke all on function public.disconnect_connection() from public, anon;
grant execute on function public.disconnect_connection() to authenticated;
