-- Connection-specific display names for anonymous collaboration.
-- The name belongs to the connection, not the global profile.

alter table public.connection_members
  add column if not exists display_name text;

drop function if exists public.connection_info();

create or replace function public.connection_info()
returns table(
  connection_id uuid,
  connection_code text,
  member_count integer,
  my_display_name text,
  partner_display_name text
)
language sql
security definer
set search_path = public
stable
as $$
  select
    c.id,
    c.code,
    count(cm.user_id)::integer,
    nullif(btrim(mine.display_name), ''),
    (
      select nullif(btrim(partner.display_name), '')
      from public.connection_members partner
      where partner.connection_id = c.id
        and partner.user_id <> auth.uid()
      limit 1
    )
  from public.connections c
  join public.connection_members mine
    on mine.connection_id = c.id
   and mine.user_id = auth.uid()
  join public.connection_members cm
    on cm.connection_id = c.id
  group by c.id, c.code, mine.display_name;
$$;

revoke all on function public.connection_info() from public, anon;
grant execute on function public.connection_info() to authenticated;

create or replace function public.create_connection(p_display_name text)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  existing uuid;
  new_id uuid;
  new_code text;
  clean_name text := nullif(btrim(p_display_name), '');
begin
  if uid is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  if clean_name is null then
    raise exception 'Bitte gib einen Namen für diese Verbindung ein.';
  end if;
  if char_length(clean_name) > 40 then
    raise exception 'Der Name darf höchstens 40 Zeichen lang sein.';
  end if;

  insert into public.profiles(id, display_name)
  values (uid, clean_name)
  on conflict (id) do update set display_name = excluded.display_name, updated_at = now();

  select connection_id into existing
  from public.connection_members
  where user_id = uid
  limit 1;

  if existing is not null then
    update public.connection_members
    set display_name = clean_name
    where connection_id = existing and user_id = uid;

    select code into new_code from public.connections where id = existing;
    return new_code;
  end if;

  loop
    new_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
    exit when not exists(select 1 from public.connections where code = new_code);
  end loop;

  insert into public.connections(code, created_by)
  values(new_code, uid)
  returning id into new_id;

  insert into public.connection_members(connection_id, user_id, display_name)
  values(new_id, uid, clean_name);

  return new_code;
end;
$$;

revoke all on function public.create_connection(text) from public, anon;
grant execute on function public.create_connection(text) to authenticated;

create or replace function public.join_connection(p_code text, p_display_name text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  cid uuid;
  member_count integer;
  clean_name text := nullif(btrim(p_display_name), '');
begin
  if uid is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;
  if p_code is null or length(trim(p_code)) < 4 then
    raise exception 'Ungültiger Verbindungscode.';
  end if;
  if clean_name is null then
    raise exception 'Bitte gib einen Namen für diese Verbindung ein.';
  end if;
  if char_length(clean_name) > 40 then
    raise exception 'Der Name darf höchstens 40 Zeichen lang sein.';
  end if;

  insert into public.profiles(id, display_name)
  values (uid, clean_name)
  on conflict (id) do update set display_name = excluded.display_name, updated_at = now();

  if exists (
    select 1
    from public.connection_members
    where user_id = uid
  ) then
    raise exception 'Dieses Gerät ist bereits mit einer Person verbunden.';
  end if;

  select id into cid
  from public.connections
  where code = upper(trim(p_code))
  for update;

  if cid is null then
    raise exception 'Verbindungscode nicht gefunden.';
  end if;

  select count(*) into member_count
  from public.connection_members
  where connection_id = cid;

  if member_count >= 2 then
    raise exception 'Diese Verbindung ist bereits vollständig.';
  end if;

  insert into public.connection_members(connection_id, user_id, display_name)
  values (cid, uid, clean_name);

  return true;
end;
$$;

revoke all on function public.join_connection(text, text) from public, anon;
grant execute on function public.join_connection(text, text) to authenticated;

create or replace function public.connection_member_display_name(
  p_connection_id uuid,
  p_user_id uuid
)
returns text
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(
    nullif(btrim(cm.display_name), ''),
    nullif(btrim(p.display_name), ''),
    'Deine verbundene Person'
  )
  from public.connection_members cm
  left join public.profiles p on p.id = cm.user_id
  where cm.connection_id = p_connection_id
    and cm.user_id = p_user_id
  limit 1;
$$;

revoke all on function public.connection_member_display_name(uuid, uuid) from public, anon;
grant execute on function public.connection_member_display_name(uuid, uuid) to authenticated;
