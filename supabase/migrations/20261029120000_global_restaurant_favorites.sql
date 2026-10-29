-- Make the restaurant collection global like the recipe library.
-- Every authenticated user can browse the same collection. Users may add,
-- edit, and remove only the entries they created.
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

create policy "restaurant favorites global read"
on public.restaurant_favorites
for select to authenticated
using (true);

create policy "restaurant favorites own insert"
on public.restaurant_favorites
for insert to authenticated
with check (user_id = (select auth.uid()));

create policy "restaurant favorites own update"
on public.restaurant_favorites
for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy "restaurant favorites own delete"
on public.restaurant_favorites
for delete to authenticated
using (user_id = (select auth.uid()));

revoke all on table public.restaurant_favorites from public, anon, authenticated;
grant select, insert, update, delete on table public.restaurant_favorites to authenticated;
