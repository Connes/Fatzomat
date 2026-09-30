-- Personal-First collaboration: explicit recipe suggestions.
-- A suggestion is a collaboration record only. It never changes a personal TodayPlan.

create table if not exists public.recipe_suggestions (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references public.connections(id) on delete cascade,
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  suggested_by uuid not null references auth.users(id) on delete cascade,
  suggested_to uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending','accepted','declined','cancelled')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  constraint recipe_suggestions_distinct_users check (suggested_by <> suggested_to)
);

create index if not exists recipe_suggestions_recipient_status_idx
  on public.recipe_suggestions(suggested_to, status, created_at desc);
create index if not exists recipe_suggestions_sender_status_idx
  on public.recipe_suggestions(suggested_by, status, created_at desc);
create index if not exists recipe_suggestions_recipe_idx
  on public.recipe_suggestions(recipe_id);
create unique index if not exists recipe_suggestions_one_pending_per_recipe_pair
  on public.recipe_suggestions(connection_id, recipe_id, suggested_by, suggested_to)
  where status = 'pending';

alter table public.recipe_suggestions enable row level security;

create policy "recipe suggestions participants read"
on public.recipe_suggestions for select to authenticated
using (
  public.is_connection_member(connection_id)
  and (suggested_by = (select auth.uid()) or suggested_to = (select auth.uid()))
);

create policy "recipe suggestions sender insert"
on public.recipe_suggestions for insert to authenticated
with check (
  suggested_by = (select auth.uid())
  and suggested_by <> suggested_to
  and public.is_connection_member(connection_id)
  and public.is_connection_member(connection_id, suggested_to)
  and exists (
    select 1
    from public.recipes r
    where r.id = recipe_id
      and (
        r.created_by = (select auth.uid())
        or exists (select 1 from public.recipe_saves rs where rs.recipe_id = r.id and rs.user_id = (select auth.uid()))
        or exists (select 1 from public.shared_recipe_plans sp where sp.recipe_id = r.id and public.is_connection_member(sp.connection_id))
        or exists (select 1 from public.recipe_suggestions old_rs where old_rs.recipe_id = r.id and old_rs.suggested_to = (select auth.uid()) and old_rs.status in ('pending','accepted') and public.is_connection_member(old_rs.connection_id))
      )
  )
);

create policy "recipe suggestions recipient update"
on public.recipe_suggestions for update to authenticated
using (
  suggested_to = (select auth.uid())
  and public.is_connection_member(connection_id)
)
with check (
  suggested_to = (select auth.uid())
  and public.is_connection_member(connection_id)
  and status in ('accepted','declined')
);

create policy "recipe suggestions sender cancel"
on public.recipe_suggestions for update to authenticated
using (
  suggested_by = (select auth.uid())
  and public.is_connection_member(connection_id)
)
with check (
  suggested_by = (select auth.uid())
  and public.is_connection_member(connection_id)
  and status = 'cancelled'
);

create or replace function public.create_recipe_suggestion(p_recipe_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  cid uuid;
  recipient uuid;
  row public.recipe_suggestions;
begin
  if uid is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  select cm.connection_id into cid
  from public.connection_members cm
  where cm.user_id = uid
  limit 1;

  if cid is null then
    raise exception 'Keine Verbindung zu einer zweiten Person vorhanden.';
  end if;

  select cm.user_id into recipient
  from public.connection_members cm
  where cm.connection_id = cid
    and cm.user_id <> uid
  limit 1;

  if recipient is null then
    raise exception 'Keine verbundene Person vorhanden.';
  end if;

  if not exists (
    select 1 from public.recipes r
    where r.id = p_recipe_id
      and (
        r.created_by = uid
        or exists (select 1 from public.recipe_saves rs where rs.recipe_id = r.id and rs.user_id = uid)
        or exists (select 1 from public.shared_recipe_plans sp where sp.recipe_id = r.id and public.is_connection_member(sp.connection_id))
        or exists (select 1 from public.recipe_suggestions old_rs where old_rs.recipe_id = r.id and old_rs.suggested_to = uid and old_rs.status in ('pending','accepted') and public.is_connection_member(old_rs.connection_id))
      )
  ) then
    raise exception 'Das Rezept ist für dich nicht freigegeben.';
  end if;

  select * into row
  from public.recipe_suggestions rs
  where rs.connection_id = cid
    and rs.recipe_id = p_recipe_id
    and rs.suggested_by = uid
    and rs.suggested_to = recipient
    and rs.status = 'pending'
  limit 1;

  if row.id is null then
    insert into public.recipe_suggestions(connection_id, recipe_id, suggested_by, suggested_to)
    values (cid, p_recipe_id, uid, recipient)
    returning * into row;
  end if;

  return jsonb_build_object(
    'id', row.id,
    'connection_id', row.connection_id,
    'recipe_id', row.recipe_id,
    'suggested_by', row.suggested_by,
    'suggested_to', row.suggested_to,
    'status', row.status,
    'created_at', row.created_at,
    'responded_at', row.responded_at
  );
end;
$$;

create or replace function public.respond_to_recipe_suggestion(
  p_suggestion_id uuid,
  p_accept boolean
)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  row public.recipe_suggestions;
begin
  if uid is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  select * into row
  from public.recipe_suggestions
  where id = p_suggestion_id
    and suggested_to = uid
    and status = 'pending'
  for update;

  if row.id is null then
    raise exception 'Der Rezeptvorschlag ist nicht mehr offen.';
  end if;

  update public.recipe_suggestions
  set status = case when p_accept then 'accepted' else 'declined' end,
      responded_at = now()
  where id = row.id;

  row.status := case when p_accept then 'accepted' else 'declined' end;
  row.responded_at := now();

  return jsonb_build_object(
    'id', row.id,
    'connection_id', row.connection_id,
    'recipe_id', row.recipe_id,
    'suggested_by', row.suggested_by,
    'suggested_to', row.suggested_to,
    'status', row.status,
    'created_at', row.created_at,
    'responded_at', row.responded_at
  );
end;
$$;

revoke all on function public.create_recipe_suggestion(uuid) from public, anon;
grant execute on function public.create_recipe_suggestion(uuid) to authenticated;
revoke all on function public.respond_to_recipe_suggestion(uuid, boolean) from public, anon;
grant execute on function public.respond_to_recipe_suggestion(uuid, boolean) to authenticated;

alter publication supabase_realtime add table public.recipe_suggestions;

-- A recipient may read the explicitly suggested recipe, but only that recipe.
drop policy if exists "recipes suggested to connection member read" on public.recipes;
create policy "recipes suggested to connection member read"
on public.recipes for select to authenticated
using (
  exists (
    select 1
    from public.recipe_suggestions rs
    where rs.recipe_id = recipes.id
      and rs.suggested_to = (select auth.uid())
      and rs.status in ('pending','accepted')
      and public.is_connection_member(rs.connection_id)
  )
);

-- Ingredients follow the same explicit-sharing rule.
drop policy if exists "recipe ingredients suggested read" on public.recipe_ingredients;
create policy "recipe ingredients suggested read"
on public.recipe_ingredients for select to authenticated
using (
  exists (
    select 1
    from public.recipe_suggestions rs
    where rs.recipe_id = recipe_ingredients.recipe_id
      and rs.suggested_to = (select auth.uid())
      and rs.status in ('pending','accepted')
      and public.is_connection_member(rs.connection_id)
  )
);

create or replace function public.guard_recipe_suggestion_update()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if NEW.connection_id <> OLD.connection_id
     or NEW.recipe_id <> OLD.recipe_id
     or NEW.suggested_by <> OLD.suggested_by
     or NEW.suggested_to <> OLD.suggested_to
     or NEW.created_at <> OLD.created_at then
    raise exception 'Die Identität eines Rezeptvorschlags kann nicht geändert werden.';
  end if;
  return NEW;
end;
$$;

revoke all on function public.guard_recipe_suggestion_update() from public, anon;
grant execute on function public.guard_recipe_suggestion_update() to authenticated;

drop trigger if exists recipe_suggestions_immutable_guard on public.recipe_suggestions;
create trigger recipe_suggestions_immutable_guard
before update on public.recipe_suggestions
for each row execute function public.guard_recipe_suggestion_update();
