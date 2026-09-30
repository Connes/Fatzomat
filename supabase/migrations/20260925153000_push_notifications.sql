create table if not exists public.push_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_token text not null unique,
  platform text not null check (platform in ('android','ios','other')),
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists idx_push_devices_user_id on public.push_devices(user_id);

alter table public.push_devices enable row level security;

drop policy if exists "push devices own read" on public.push_devices;
create policy "push devices own read"
on public.push_devices for select to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "push devices own insert" on public.push_devices;
create policy "push devices own insert"
on public.push_devices for insert to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "push devices own update" on public.push_devices;
create policy "push devices own update"
on public.push_devices for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

drop policy if exists "push devices own delete" on public.push_devices;
create policy "push devices own delete"
on public.push_devices for delete to authenticated
using (user_id = (select auth.uid()));
