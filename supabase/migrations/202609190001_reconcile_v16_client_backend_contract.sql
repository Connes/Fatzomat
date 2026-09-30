-- V48: make the Today workflow deterministic while allowing a cancelled plan
-- to be replaced later on the same day.
alter table public.shared_recipe_plans
  drop constraint if exists shared_recipe_plans_connection_id_plan_date_key;

create unique index if not exists shared_recipe_plans_one_active_per_connection_day
  on public.shared_recipe_plans(connection_id, plan_date)
  where status <> 'cancelled';
-- v51: keep connection status in sync on both devices.
do 'begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = ''supabase_realtime''
      and schemaname = ''public''
      and tablename = ''connection_members''
  ) then
    execute ''alter publication supabase_realtime add table public.connection_members'';
  end if;
end';
-- V54: editable shopping list. Manual items never modify the source recipe.
alter table public.shopping_items
  add column if not exists source text not null default 'recipe';

alter table public.shopping_items
  drop constraint if exists shopping_items_source_check;
alter table public.shopping_items
  add constraint shopping_items_source_check check (source in ('recipe','manual'));

create index if not exists idx_shopping_items_plan_source
  on public.shopping_items(shared_recipe_plan_id, source);
-- V57 / Part 1: structured two-person decision requests.
-- This is intentionally not a chat/message system. A request has one sender,
-- one recipient and one eventual decision result.

create table if not exists public.decision_requests (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references public.connections(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  assigned_to uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending','accepted','resolved','cancelled','expired')),
  decision_mode text,
  result_type text,
  result_id text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  check (created_by <> assigned_to)
);

create index if not exists idx_decision_requests_assigned_status
  on public.decision_requests(assigned_to, status, created_at desc);
create index if not exists idx_decision_requests_created_status
  on public.decision_requests(created_by, status, created_at desc);
create index if not exists idx_decision_requests_connection_status
  on public.decision_requests(connection_id, status, created_at desc);

create unique index if not exists decision_requests_one_pending_per_connection
  on public.decision_requests(connection_id)
  where status = 'pending';

alter table public.decision_requests enable row level security;

drop policy if exists "decision requests connection members can read" on public.decision_requests;

create policy "decision requests connection members can read"
on public.decision_requests for select to authenticated
using (public.is_connection_member(connection_id));

drop policy if exists "decision requests sender insert" on public.decision_requests;

create policy "decision requests sender insert"
on public.decision_requests for insert to authenticated
with check (
  created_by = (select auth.uid())
  and public.is_connection_member(connection_id)
  and public.is_connection_member(connection_id, assigned_to)
  and assigned_to <> (select auth.uid())
);

drop policy if exists "decision requests participants update" on public.decision_requests;

create policy "decision requests participants update"
on public.decision_requests for update to authenticated
using (
  public.is_connection_member(connection_id)
  and (created_by = (select auth.uid()) or assigned_to = (select auth.uid()))
)
with check (
  public.is_connection_member(connection_id)
  and (created_by = (select auth.uid()) or assigned_to = (select auth.uid()))
);

drop policy if exists "decision requests sender delete" on public.decision_requests;

create policy "decision requests sender delete"
on public.decision_requests for delete to authenticated
using (created_by = (select auth.uid()));

create or replace function public.create_decision_request(p_assigned_to uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  cid uuid;
  request_row public.decision_requests;
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

  if p_assigned_to is null or p_assigned_to = uid
     or not public.is_connection_member(cid, p_assigned_to) then
    raise exception 'Die ausgewählte Person gehört nicht zur Verbindung.';
  end if;

  if exists (
    select 1 from public.decision_requests dr
    where dr.connection_id = cid and dr.status = 'pending'
  ) then
    raise exception 'Für eure Verbindung läuft bereits eine Entscheidung.';
  end if;

  insert into public.decision_requests(connection_id, created_by, assigned_to)
  values (cid, uid, p_assigned_to)
  returning * into request_row;

  return jsonb_build_object(
    'id', request_row.id,
    'connection_id', request_row.connection_id,
    'created_by', request_row.created_by,
    'assigned_to', request_row.assigned_to,
    'status', request_row.status,
    'decision_mode', request_row.decision_mode,
    'result_type', request_row.result_type,
    'result_id', request_row.result_id,
    'created_at', request_row.created_at,
    'resolved_at', request_row.resolved_at
  );
end;
$$;

revoke all on function public.create_decision_request(uuid) from public, anon;
grant execute on function public.create_decision_request(uuid) to authenticated;

do 'begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = ''supabase_realtime''
      and schemaname = ''public''
      and tablename = ''decision_requests''
  ) then
    execute ''alter publication supabase_realtime add table public.decision_requests'';
  end if;
end';
-- V57 / Part 2: safe participant actions for decision requests.

-- State changes happen only through the RPCs below. This keeps clients from
-- changing decision results or statuses directly.
drop policy if exists "decision requests participants update" on public.decision_requests;

create or replace function public.accept_decision_request(p_request_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  changed integer;
begin
  update public.decision_requests
  set status = 'accepted'
  where id = p_request_id
    and assigned_to = auth.uid()
    and status = 'pending';
  get diagnostics changed = row_count;
  return changed = 1;
end;
$$;

revoke all on function public.accept_decision_request(uuid) from public, anon;
grant execute on function public.accept_decision_request(uuid) to authenticated;

create or replace function public.resolve_decision_request(
  p_request_id uuid,
  p_decision_mode text,
  p_result_type text,
  p_result_id text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  changed integer;
begin
  if p_decision_mode is null or p_result_type is null or p_result_id is null or btrim(p_result_id) = '' then
    raise exception 'Eine vollständige Entscheidung ist erforderlich.';
  end if;

  update public.decision_requests
  set status = 'resolved',
      decision_mode = p_decision_mode,
      result_type = p_result_type,
      result_id = p_result_id,
      resolved_at = now()
  where id = p_request_id
    and assigned_to = auth.uid()
    and status in ('pending', 'accepted');

  get diagnostics changed = row_count;
  if changed <> 1 then
    raise exception 'Die Entscheidungsanfrage ist nicht mehr offen.';
  end if;
  return true;
end;
$$;

revoke all on function public.resolve_decision_request(uuid,text,text,text) from public, anon;
grant execute on function public.resolve_decision_request(uuid,text,text,text) to authenticated;

create or replace function public.cancel_decision_request(p_request_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  changed integer;
begin
  update public.decision_requests
  set status = 'cancelled', resolved_at = now()
  where id = p_request_id
    and created_by = auth.uid()
    and status in ('pending', 'accepted');
  get diagnostics changed = row_count;
  return changed = 1;
end;
$$;

revoke all on function public.cancel_decision_request(uuid) from public, anon;
grant execute on function public.cancel_decision_request(uuid) to authenticated;
-- V57 / Part 3: resolve a decision atomically and reflect the result on both devices.
-- For a recipe decision, resolving the request also creates Today + shopping data.

create or replace function public.resolve_decision_request(
  p_request_id uuid,
  p_decision_mode text,
  p_result_type text,
  p_result_id text,
  p_servings integer default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  changed integer;
  request_row public.decision_requests;
  plan_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  if p_decision_mode is null or p_result_type is null or p_result_id is null or btrim(p_result_id) = '' then
    raise exception 'Eine vollständige Entscheidung ist erforderlich.';
  end if;

  select * into request_row
  from public.decision_requests dr
  where dr.id = p_request_id
    and dr.assigned_to = auth.uid()
    and dr.status in ('pending', 'accepted')
  for update;

  if request_row.id is null then
    raise exception 'Die Entscheidungsanfrage ist nicht mehr offen.';
  end if;

  -- A recipe decision is the one case where the result becomes a shared Today plan.
  -- The existing RPC also creates the matching shopping items and enforces recipe access.
  if p_result_type = 'recipe' then
    if p_decision_mode <> 'cook' then
      raise exception 'Ein Rezept kann nur als Kochentscheidung gespeichert werden.';
    end if;
    plan_id := public.share_recipe_for_today(p_result_id::uuid, p_servings);
  end if;

  update public.decision_requests
  set status = 'resolved',
      decision_mode = p_decision_mode,
      result_type = p_result_type,
      result_id = p_result_id,
      resolved_at = now()
  where id = p_request_id
    and assigned_to = auth.uid()
    and status in ('pending', 'accepted');

  get diagnostics changed = row_count;
  if changed <> 1 then
    -- Keep the Today creation and request state consistent if a concurrent action won.
    raise exception 'Die Entscheidungsanfrage ist nicht mehr offen.';
  end if;

  -- For non-recipe decisions there is no TodayPlan. Give the sender an explicit
  -- in-app notification; recipe decisions already notify the sender via
  -- share_recipe_for_today and also appear in Today through Realtime.
  if p_result_type <> 'recipe' then
    insert into public.app_notifications(user_id, type, title, body)
    values (
      request_row.created_by,
      'decision_resolved',
      'Entscheidung getroffen',
      'Deine verbundene Person hat entschieden: ' || btrim(p_result_id) || '.'
    );
  end if;

  return true;
end;
$$;

revoke all on function public.resolve_decision_request(uuid,text,text,text) from public, anon;
grant execute on function public.resolve_decision_request(uuid,text,text,text,integer) to authenticated;
-- V57 / Part 4: in-app notifications for the decision handoff.
-- Push delivery remains provider-dependent. The app now has a realtime inbox
-- so the collaboration flow is useful without requiring FCM/APNs credentials.

alter table public.app_notifications
  add column if not exists decision_request_id uuid
  references public.decision_requests(id) on delete cascade;

create index if not exists idx_notifications_user_unread
  on public.app_notifications(user_id, created_at desc)
  where read_at is null;

-- Realtime delivery for the notification inbox.
do $realtime$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'app_notifications'
  ) then
    alter publication supabase_realtime add table public.app_notifications;
  end if;
end
$realtime$;

create or replace function public.create_decision_request(p_assigned_to uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  cid uuid;
  request_row public.decision_requests;
  sender_name text;
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

  if p_assigned_to is null or p_assigned_to = uid
     or not public.is_connection_member(cid, p_assigned_to) then
    raise exception 'Die ausgewählte Person gehört nicht zur Verbindung.';
  end if;

  if exists (
    select 1 from public.decision_requests dr
    where dr.connection_id = cid and dr.status = 'pending'
  ) then
    raise exception 'Für eure Verbindung läuft bereits eine Entscheidung.';
  end if;

  insert into public.decision_requests(connection_id, created_by, assigned_to)
  values (cid, uid, p_assigned_to)
  returning * into request_row;

  select nullif(btrim(p.display_name), '') into sender_name
  from public.profiles p
  where p.id = uid;

  insert into public.app_notifications(
    user_id, type, title, body, decision_request_id
  ) values (
    p_assigned_to,
    'decision_request',
    'Du entscheidest heute',
    coalesce(sender_name, 'Deine Verbindung') || ' hat dir die Entscheidung für heute übergeben.',
    request_row.id
  );

  return jsonb_build_object(
    'id', request_row.id,
    'connection_id', request_row.connection_id,
    'created_by', request_row.created_by,
    'assigned_to', request_row.assigned_to,
    'status', request_row.status,
    'decision_mode', request_row.decision_mode,
    'result_type', request_row.result_type,
    'result_id', request_row.result_id,
    'created_at', request_row.created_at,
    'resolved_at', request_row.resolved_at
  );
end;
$$;

revoke all on function public.create_decision_request(uuid) from public, anon;
grant execute on function public.create_decision_request(uuid) to authenticated;

create or replace function public.accept_decision_request(p_request_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  changed integer;
  request_row public.decision_requests;
  accepter_name text;
begin
  select * into request_row
  from public.decision_requests
  where id = p_request_id
    and assigned_to = auth.uid()
    and status = 'pending'
  for update;

  if request_row.id is null then
    return false;
  end if;

  update public.decision_requests
  set status = 'accepted'
  where id = p_request_id;
  get diagnostics changed = row_count;

  if changed = 1 then
    select nullif(btrim(p.display_name), '') into accepter_name
    from public.profiles p
    where p.id = auth.uid();

    insert into public.app_notifications(user_id, type, title, body, decision_request_id)
    values (
      request_row.created_by,
      'decision_request_accepted',
      'Entscheidung angenommen',
      coalesce(accepter_name, 'Deine Verbindung') || ' entscheidet jetzt, was ihr heute esst.',
      request_row.id
    );
  end if;

  return changed = 1;
end;
$$;

revoke all on function public.accept_decision_request(uuid) from public, anon;
grant execute on function public.accept_decision_request(uuid) to authenticated;
-- V81: editable shared Today plan with synchronized servings and replacement.

alter table public.shared_recipe_plans
  add column if not exists servings integer;

update public.shared_recipe_plans sp
set servings = greatest(coalesce(r.servings, 2), 1)
from public.recipes r
where r.id = sp.recipe_id and sp.servings is null;

alter table public.shared_recipe_plans
  alter column servings set default 2;

alter table public.shared_recipe_plans
  drop constraint if exists shared_recipe_plans_servings_check;

alter table public.shared_recipe_plans
  add constraint shared_recipe_plans_servings_check check (servings between 1 and 12);

create or replace function public.update_shared_recipe_plan_servings(p_plan_id uuid, p_servings integer)
returns boolean language plpgsql security definer set search_path=public as $$
declare
  cid uuid;
  rid uuid;
  base_servings integer;
begin
  if auth.uid() is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  if p_servings < 1 or p_servings > 12 then raise exception 'Ungültige Personenzahl.'; end if;
  select connection_id, recipe_id into cid, rid
  from public.shared_recipe_plans
  where id = p_plan_id and plan_date = current_date and status <> 'cancelled';
  if cid is null or not public.is_connection_member(cid) then raise exception 'Tagesplan ist nicht verfügbar.'; end if;
  select servings into base_servings from public.recipes where id = rid;
  if base_servings is null or base_servings < 1 then base_servings := 1; end if;

  update public.shared_recipe_plans set servings = p_servings where id = p_plan_id;
  delete from public.shopping_items where shared_recipe_plan_id = p_plan_id and source = 'recipe';
  insert into public.shopping_items(shared_recipe_plan_id,food_id,name,quantity,unit,source)
    select p_plan_id,ri.food_id,ri.name,round((ri.quantity * p_servings::numeric / greatest(base_servings,1))::numeric, 2),ri.unit,'recipe'
    from public.recipe_ingredients ri where ri.recipe_id=rid;
  return true;
end; $$;
revoke execute on function public.update_shared_recipe_plan_servings(uuid,integer) from public, anon;
grant execute on function public.update_shared_recipe_plan_servings(uuid,integer) to authenticated;

create or replace function public.cancel_shared_recipe_plan(p_plan_id uuid)
returns boolean language plpgsql security definer set search_path=public as $$
begin
  if auth.uid() is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  delete from public.shopping_items where shared_recipe_plan_id = p_plan_id and source = 'recipe';
  update public.shared_recipe_plans set status='cancelled'
    where id=p_plan_id and plan_date=current_date and status <> 'cancelled'
      and public.is_connection_member(connection_id);
  return found;
end; $$;
revoke execute on function public.cancel_shared_recipe_plan(uuid) from public, anon;
grant execute on function public.cancel_shared_recipe_plan(uuid) to authenticated;

create or replace function public.replace_shared_recipe_plan(p_plan_id uuid, p_recipe_id uuid, p_servings integer default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare
  cid uuid;
  target integer;
  base_servings integer;
  partner uuid;
begin
  if auth.uid() is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  select connection_id into cid from public.shared_recipe_plans
    where id=p_plan_id and plan_date=current_date and status <> 'cancelled';
  if cid is null or not public.is_connection_member(cid) then raise exception 'Tagesplan ist nicht verfügbar.'; end if;
  select r.servings into base_servings from public.recipes r
    where r.id=p_recipe_id and (r.created_by=auth.uid() or exists(select 1 from public.recipe_saves rs where rs.recipe_id=r.id and rs.user_id=auth.uid()));
  if base_servings is null then raise exception 'Rezept ist nicht verfügbar.'; end if;
  target := coalesce(p_servings, base_servings);
  if target < 1 or target > 12 then raise exception 'Ungültige Personenzahl.'; end if;

  delete from public.shopping_items where shared_recipe_plan_id = p_plan_id and source = 'recipe';
  update public.shared_recipe_plans
    set recipe_id=p_recipe_id, servings=target, status='planned'
    where id=p_plan_id;
  insert into public.shopping_items(shared_recipe_plan_id,food_id,name,quantity,unit,source)
    select p_plan_id,ri.food_id,ri.name,round((ri.quantity * target::numeric / greatest(base_servings,1))::numeric, 2),ri.unit,'recipe'
    from public.recipe_ingredients ri where ri.recipe_id=p_recipe_id;

  select cm.user_id into partner from public.connection_members cm
    where cm.connection_id=cid and cm.user_id<>auth.uid() limit 1;
  if partner is not null then
    insert into public.app_notifications(user_id,type,title,body,recipe_id,shared_recipe_plan_id)
    select partner,'shared_recipe','Rezept für heute geändert','Euer heutiges Rezept wurde geändert.',p_recipe_id,p_plan_id;
  end if;
  return p_plan_id;
end; $$;
revoke execute on function public.replace_shared_recipe_plan(uuid,uuid,integer) from public, anon;
grant execute on function public.replace_shared_recipe_plan(uuid,uuid,integer) to authenticated;

-- Keep the original creation RPC in sync with the new servings column.
create or replace function public.share_recipe_for_today(p_recipe_id uuid, p_servings integer default null)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare cid uuid; pid uuid; partner uuid; rid uuid; base_servings integer; target_servings integer;
begin
  if auth.uid() is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  select cm.connection_id into cid from public.connection_members cm where cm.user_id=auth.uid() limit 1;
  if cid is null then raise exception 'Keine Verbindung zu einer zweiten Person vorhanden.'; end if;
  select r.id, r.servings into rid, base_servings from public.recipes r
    where r.id=p_recipe_id and (r.created_by=auth.uid() or exists(select 1 from public.recipe_saves rs where rs.recipe_id=r.id and rs.user_id=auth.uid())) limit 1;
  if rid is null then raise exception 'Rezept ist nicht verfügbar.'; end if;
  target_servings := coalesce(p_servings, base_servings);
  if target_servings < 1 or target_servings > 12 then raise exception 'Ungültige Personenzahl.'; end if;
  select sp.id into pid from public.shared_recipe_plans sp where sp.connection_id=cid and sp.plan_date=current_date and sp.status <> 'cancelled';
  if pid is not null then raise exception 'Für heute ist bereits ein gemeinsames Rezept ausgewählt.'; end if;
  insert into public.shared_recipe_plans(connection_id,recipe_id,shared_by,plan_date,status,servings) values(cid,rid,auth.uid(),current_date,'planned',target_servings) returning id into pid;
  insert into public.shopping_items(shared_recipe_plan_id,food_id,name,quantity,unit,source)
    select pid,ri.food_id,ri.name,round((ri.quantity * target_servings::numeric / greatest(base_servings,1))::numeric, 2),ri.unit,'recipe'
    from public.recipe_ingredients ri where ri.recipe_id=rid;
  select cm.user_id into partner from public.connection_members cm where cm.connection_id=cid and cm.user_id<>auth.uid() limit 1;
  if partner is not null then
    insert into public.app_notifications(user_id,type,title,body,recipe_id,shared_recipe_plan_id)
    select partner,'shared_recipe','Neues Rezept für heute',r.name || ' wurde für euch heute ausgewählt.',rid,pid from public.recipes r where r.id=rid;
  end if;
  return pid;
end; $$;
revoke execute on function public.share_recipe_for_today(uuid,integer) from public, anon;
grant execute on function public.share_recipe_for_today(uuid,integer) to authenticated;
-- V82: make the decision handoff lifecycle visible and recoverable.
-- Cancelling an active request also informs the person who received it.

create or replace function public.cancel_decision_request(p_request_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  changed integer;
  request_row public.decision_requests;
  sender_name text;
begin
  select * into request_row
  from public.decision_requests
  where id = p_request_id
    and created_by = auth.uid()
    and status in ('pending', 'accepted')
  for update;

  if request_row.id is null then
    return false;
  end if;

  update public.decision_requests
  set status = 'cancelled', resolved_at = now()
  where id = p_request_id;
  get diagnostics changed = row_count;

  if changed = 1 then
    select nullif(btrim(p.display_name), '') into sender_name
    from public.profiles p
    where p.id = auth.uid();

    insert into public.app_notifications(user_id, type, title, body, decision_request_id)
    values (
      request_row.assigned_to,
      'decision_request_cancelled',
      'Entscheidungsanfrage zurückgenommen',
      coalesce(sender_name, 'Deine Verbindung') || ' hat die Entscheidung für heute zurückgenommen.',
      request_row.id
    );
  end if;

  return changed = 1;
end;
$$;

revoke all on function public.cancel_decision_request(uuid) from public, anon;
grant execute on function public.cancel_decision_request(uuid) to authenticated;

-- The current Flutter client uses the 5-argument atomic resolver. The older
-- 4-argument compatibility overload is retained in migration history but must
-- not remain executable by client roles.
do $$
begin
  if exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'resolve_decision_request'
      and pg_get_function_identity_arguments(p.oid) = 'p_request_id uuid, p_decision_mode text, p_result_type text, p_result_id text'
  ) then
    revoke all on function public.resolve_decision_request(uuid,text,text,text) from public, anon, authenticated;
  end if;
end $$;

