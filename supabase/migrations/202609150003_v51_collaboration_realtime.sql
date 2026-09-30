-- v51: keep connection status in sync on both devices.
do $realtime$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'connection_members'
  ) then
    alter publication supabase_realtime add table public.connection_members;
  end if;
end
$realtime$;
