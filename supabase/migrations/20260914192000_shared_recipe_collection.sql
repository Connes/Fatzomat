-- v40: optional two-person collaboration around a shared recipe collection.
create table if not exists public.connections (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.connection_members (
  connection_id uuid not null references public.connections(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (connection_id, user_id),
  unique (user_id)
);

create table if not exists public.recipe_saves (
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  saved_at timestamptz not null default now(),
  primary key (recipe_id, user_id)
);

create table if not exists public.shared_recipe_plans (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references public.connections(id) on delete cascade,
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  shared_by uuid not null references auth.users(id) on delete cascade,
  plan_date date not null default current_date,
  status text not null default 'planned' check (status in ('planned','shopping','cooked','cancelled')),
  created_at timestamptz not null default now(),
  unique (connection_id, plan_date)
);

create table if not exists public.shopping_items (
  id uuid primary key default gen_random_uuid(),
  shared_recipe_plan_id uuid not null references public.shared_recipe_plans(id) on delete cascade,
  food_id text references public.foods(id) on delete set null,
  name text not null,
  quantity numeric not null default 1 check (quantity > 0),
  unit text not null,
  checked boolean not null default false,
  checked_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.app_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  recipe_id uuid references public.recipes(id) on delete cascade,
  shared_recipe_plan_id uuid references public.shared_recipe_plans(id) on delete cascade,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_connection_members_user on public.connection_members(user_id);
create index if not exists idx_recipe_saves_user on public.recipe_saves(user_id, saved_at desc);
create index if not exists idx_shared_plans_connection_date on public.shared_recipe_plans(connection_id, plan_date desc);
create index if not exists idx_shopping_items_plan on public.shopping_items(shared_recipe_plan_id);
create index if not exists idx_notifications_user_created on public.app_notifications(user_id, created_at desc);

alter table public.connections enable row level security;
alter table public.connection_members enable row level security;
alter table public.recipe_saves enable row level security;
alter table public.shared_recipe_plans enable row level security;
alter table public.shopping_items enable row level security;
alter table public.app_notifications enable row level security;

create or replace function public.is_connection_member(p_connection_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.connection_members cm
    where cm.connection_id = p_connection_id and cm.user_id = p_user_id
  );
$$;

create or replace function public.current_connection_id()
returns uuid
language sql
security definer
set search_path = public
stable
as $$
  select cm.connection_id from public.connection_members cm
  where cm.user_id = auth.uid()
  limit 1;
$$;

create or replace function public.create_connection()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  existing uuid;
  new_id uuid;
  new_code text;
begin
  select connection_id into existing from public.connection_members where user_id = auth.uid() limit 1;
  if existing is not null then
    select code into new_code from public.connections where id = existing;
    return new_code;
  end if;

  loop
    new_code := upper(substr(encode(gen_random_bytes(6), 'hex'), 1, 8));
    exit when not exists (select 1 from public.connections where code = new_code);
  end loop;

  insert into public.connections(code, created_by) values (new_code, auth.uid()) returning id into new_id;
  insert into public.connection_members(connection_id, user_id) values (new_id, auth.uid());
  return new_code;
end;
$$;

create or replace function public.join_connection(p_code text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  cid uuid;
  member_count integer;
begin
  if p_code is null or length(trim(p_code)) < 4 then raise exception 'Ungültiger Verbindungscode.'; end if;
  if exists (select 1 from public.connection_members where user_id = auth.uid()) then
    raise exception 'Dieses Gerät ist bereits mit einer Person verbunden.';
  end if;
  select id into cid from public.connections where code = upper(trim(p_code));
  if cid is null then raise exception 'Verbindungscode nicht gefunden.'; end if;
  select count(*) into member_count from public.connection_members where connection_id = cid;
  if member_count >= 2 then raise exception 'Diese Verbindung ist bereits vollständig.'; end if;
  insert into public.connection_members(connection_id, user_id) values (cid, auth.uid());
  return true;
end;
$$;

revoke all on function public.create_connection() from public, anon;
revoke all on function public.join_connection(text) from public, anon;
grant execute on function public.create_connection() to authenticated;
grant execute on function public.join_connection(text) to authenticated;

drop policy if exists "connections own membership" on public.connections;
create policy "connections own membership" on public.connections for select to authenticated
using (public.is_connection_member(id));

drop policy if exists "connection members same connection" on public.connection_members;
create policy "connection members same connection" on public.connection_members for select to authenticated
using (public.is_connection_member(connection_id));

drop policy if exists "recipe saves shared" on public.recipe_saves;
create policy "recipe saves shared" on public.recipe_saves for select to authenticated
using (
  user_id = (select auth.uid())
  or (
    public.current_connection_id() is not null
    and exists (
      select 1 from public.connection_members cm
      where cm.connection_id = public.current_connection_id() and cm.user_id = recipe_saves.user_id
    )
  )
);
create policy "recipe saves own insert" on public.recipe_saves for insert to authenticated
with check (user_id = (select auth.uid()));
create policy "recipe saves own delete" on public.recipe_saves for delete to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "recipes owner or shared" on public.recipes;
create policy "recipes owner or shared" on public.recipes for select to authenticated
using (
  created_by = (select auth.uid())
  or exists (select 1 from public.recipe_saves rs where rs.recipe_id = recipes.id and rs.user_id = (select auth.uid()))
  or exists (select 1 from public.recipe_saves rs where rs.recipe_id = recipes.id and public.is_connection_member(public.current_connection_id(), rs.user_id))
  or exists (select 1 from public.shared_recipe_plans sp where sp.recipe_id = recipes.id and public.is_connection_member(sp.connection_id))
);

create policy "shared plans members" on public.shared_recipe_plans for select to authenticated
using (public.is_connection_member(connection_id));
create policy "shared plans own insert" on public.shared_recipe_plans for insert to authenticated
with check (shared_by = (select auth.uid()) and public.is_connection_member(connection_id));
create policy "shared plans member update" on public.shared_recipe_plans for update to authenticated
using (public.is_connection_member(connection_id))
with check (public.is_connection_member(connection_id));
create policy "shared plans creator delete" on public.shared_recipe_plans for delete to authenticated
using (shared_by = (select auth.uid()));

create policy "shopping members" on public.shopping_items for select to authenticated
using (exists (select 1 from public.shared_recipe_plans sp where sp.id = shared_recipe_plan_id and public.is_connection_member(sp.connection_id)));
create policy "shopping member insert" on public.shopping_items for insert to authenticated
with check (exists (select 1 from public.shared_recipe_plans sp where sp.id = shared_recipe_plan_id and public.is_connection_member(sp.connection_id)));
create policy "shopping member update" on public.shopping_items for update to authenticated
using (exists (select 1 from public.shared_recipe_plans sp where sp.id = shared_recipe_plan_id and public.is_connection_member(sp.connection_id)))
with check (exists (select 1 from public.shared_recipe_plans sp where sp.id = shared_recipe_plan_id and public.is_connection_member(sp.connection_id)));
create policy "shopping member delete" on public.shopping_items for delete to authenticated
using (exists (select 1 from public.shared_recipe_plans sp where sp.id = shared_recipe_plan_id and public.is_connection_member(sp.connection_id)));

create policy "notifications own" on public.app_notifications for select to authenticated
using (user_id = (select auth.uid()));
create policy "notifications own update" on public.app_notifications for update to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- Recipe collection should be accessible across a connection. Replace the old owner-only policy.
drop policy if exists "own recipes" on public.recipes;
create policy "recipes own write" on public.recipes for insert to authenticated
with check (created_by = (select auth.uid()));
create policy "recipes own update" on public.recipes for update to authenticated
using (created_by = (select auth.uid())) with check (created_by = (select auth.uid()));
create policy "recipes own delete" on public.recipes for delete to authenticated
using (created_by = (select auth.uid()));
