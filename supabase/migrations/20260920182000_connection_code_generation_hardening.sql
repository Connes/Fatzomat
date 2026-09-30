-- Use the UUID generator already available in the project for short connection codes.
create or replace function public.create_connection()
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  existing uuid;
  new_id uuid;
  new_code text;
begin
  if auth.uid() is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  select connection_id into existing
  from public.connection_members
  where user_id = auth.uid()
  limit 1;

  if existing is not null then
    select code into new_code from public.connections where id = existing;
    return new_code;
  end if;

  loop
    new_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
    exit when not exists(select 1 from public.connections where code = new_code);
  end loop;

  insert into public.connections(code, created_by)
  values(new_code, auth.uid())
  returning id into new_id;

  insert into public.connection_members(connection_id, user_id)
  values(new_id, auth.uid());

  return new_code;
end;
$$;

revoke all on function public.create_connection() from public, anon;
grant execute on function public.create_connection() to authenticated;
