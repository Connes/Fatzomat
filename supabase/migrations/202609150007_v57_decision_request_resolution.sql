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
