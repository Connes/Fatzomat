-- Make the restaurant collection global like the recipe library.
-- Every authenticated user can browse, edit, and remove the shared collection.
alter table public.restaurant_favorites
  alter column user_id drop not null;

do $$
declare fk_name text;
begin
  select con.conname into fk_name
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  join pg_namespace ns on ns.oid = rel.relnamespace
  where ns.nspname = 'public'
    and rel.relname = 'restaurant_favorites'
    and con.contype = 'f'
    and con.confrelid = 'auth.users'::regclass
    and pg_get_constraintdef(con.oid) like '%(user_id)%'
  limit 1;
  if fk_name is not null then
    execute format('alter table public.restaurant_favorites drop constraint %I', fk_name);
  end if;
end $$;

alter table public.restaurant_favorites
  add constraint restaurant_favorites_user_id_fkey
  foreign key (user_id) references auth.users(id) on delete set null;

drop index if exists public.restaurant_favorites_user_identity_idx;
create unique index restaurant_favorites_global_identity_idx
  on public.restaurant_favorites (
    lower(btrim(name)),
    lower(btrim(coalesce(address, '')))
  );

drop policy if exists "restaurant favorites own access" on public.restaurant_favorites;
drop policy if exists "restaurant favorites global read" on public.restaurant_favorites;
drop policy if exists "restaurant favorites own insert" on public.restaurant_favorites;
drop policy if exists "restaurant favorites own update" on public.restaurant_favorites;
drop policy if exists "restaurant favorites own delete" on public.restaurant_favorites;
drop policy if exists "restaurant favorites global update" on public.restaurant_favorites;
drop policy if exists "restaurant favorites global delete" on public.restaurant_favorites;

create policy "restaurant favorites global read"
on public.restaurant_favorites
for select to authenticated
using (true);

create policy "restaurant favorites own insert"
on public.restaurant_favorites
for insert to authenticated
with check (user_id = (select auth.uid()));

create policy "restaurant favorites global update"
on public.restaurant_favorites
for update to authenticated
using (true)
with check (true);

create policy "restaurant favorites global delete"
on public.restaurant_favorites
for delete to authenticated
using (true);

revoke all on table public.restaurant_favorites from public, anon, authenticated;
grant select, insert, update, delete on table public.restaurant_favorites to authenticated;


-- Restaurant edits should stay silent; only deletions notify the connected person.
drop trigger if exists restaurant_favorites_notify_update on public.restaurant_favorites;

create or replace function public.notify_connection_restaurant_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  actor uuid := auth.uid();
  recipient uuid;
  actor_name text;
  restaurant_name text;
begin
  if tg_op <> 'DELETE' or actor is null then
    return coalesce(new, old);
  end if;

  select cm.user_id into recipient
  from public.connection_members cm
  join public.connection_members actor_member
    on actor_member.connection_id = cm.connection_id
  where actor_member.user_id = actor
    and cm.user_id <> actor
  limit 1;

  if recipient is null then
    return old;
  end if;

  select nullif(btrim(display_name), '') into actor_name
  from public.profiles where id = actor;

  restaurant_name := old.name;

  insert into public.app_notifications(user_id, type, title, body)
  values (
    recipient,
    'restaurant_favorite_deleted',
    'Lieblingsrestaurant gelöscht',
    coalesce(actor_name, 'Deine verbundene Person') || ' hat das Restaurant „' ||
      coalesce(restaurant_name, 'Unbekannt') || '“ gelöscht.'
  );

  return old;
end;
$$;

drop trigger if exists restaurant_favorites_notify_delete on public.restaurant_favorites;
create trigger restaurant_favorites_notify_delete
after delete on public.restaurant_favorites
for each row execute function public.notify_connection_restaurant_change();

revoke all on function public.notify_connection_restaurant_change() from public, anon, authenticated;
