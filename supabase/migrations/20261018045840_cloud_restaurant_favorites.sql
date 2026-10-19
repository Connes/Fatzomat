-- Restaurant favorites belong to a user account, not a device.
-- RLS ensures favorites sync across that user's devices without exposing them
-- to other authenticated users.
create table if not exists public.restaurant_favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (length(btrim(name)) > 0),
  cuisine text,
  address text,
  phone text,
  website text,
  opening_hours text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists restaurant_favorites_user_name_idx
  on public.restaurant_favorites(user_id, lower(name));

create unique index if not exists restaurant_favorites_user_identity_idx
  on public.restaurant_favorites(user_id, lower(btrim(name)), lower(btrim(coalesce(address, ''))));

alter table public.restaurant_favorites enable row level security;

drop policy if exists "restaurant favorites own access" on public.restaurant_favorites;
create policy "restaurant favorites own access"
on public.restaurant_favorites
for all to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

grant select, insert, update, delete on public.restaurant_favorites to authenticated;
