-- v51: keep connection status in sync on both devices.
alter publication supabase_realtime add table public.connection_members;
