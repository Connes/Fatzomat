-- A connection represents one shared relationship, not independent memberships.
-- Removing either member (including auth.users ON DELETE CASCADE) dissolves the
-- connection for both participants. Personal data is stored separately and is
-- deliberately not deleted here.
create or replace function public.cleanup_connection_after_member_removal()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- When the connection itself is being deleted, its FK cascade also deletes
  -- memberships. The parent row is already gone, so this condition prevents a
  -- recursive delete of that same connection.
  if exists (
    select 1 from public.connections c where c.id = old.connection_id
  ) and (
    select count(*)
    from public.connection_members cm
    where cm.connection_id = old.connection_id
  ) < 2 then
    delete from public.connections
    where id = old.connection_id;
  end if;

  return old;
end;
$$;

drop trigger if exists cleanup_connection_after_member_removal
  on public.connection_members;

create trigger cleanup_connection_after_member_removal
after delete on public.connection_members
for each row
execute function public.cleanup_connection_after_member_removal();

revoke all on function public.cleanup_connection_after_member_removal() from public, anon, authenticated;

-- Explicit disconnect must dissolve the relationship itself, so both members
-- disappear in the same transaction. Authorize only the caller's own connection.
create or replace function public.disconnect_connection()
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  cid uuid;
begin
  if auth.uid() is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  select cm.connection_id
    into cid
  from public.connection_members cm
  where cm.user_id = auth.uid()
  limit 1
  for update;

  if cid is null then
    return false;
  end if;

  delete from public.connections c
  where c.id = cid
    and exists (
      select 1
      from public.connection_members mine
      where mine.connection_id = c.id
        and mine.user_id = auth.uid()
    );

  return found;
end;
$$;

revoke all on function public.disconnect_connection() from public, anon;
grant execute on function public.disconnect_connection() to authenticated;
