-- Fix personal recipe selection while keeping authorization explicit.
--
-- The personal Today write spans several RLS-protected tables. Running this
-- atomic operation as SECURITY INVOKER can make the authorization path depend
-- on cross-table RLS policies (recipes -> personal_today_plans and back), which
-- is especially fragile once resolved-decision read policies are present.
--
-- SECURITY DEFINER is intentionally scoped to this one RPC. The function still
-- derives the acting user exclusively from auth.uid() and independently checks
-- that the recipe is either owned by or saved by that same user. It never
-- accepts a target user id and therefore cannot be used to write another
-- person's personal TodayPlan.
create or replace function public.set_personal_today_plan(
  p_recipe_id uuid,
  p_servings integer default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  pid uuid;
  previous_recipe uuid;
  base_servings integer;
  target_servings integer;
  action_name text;
begin
  if uid is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  if p_recipe_id is null then
    raise exception 'Keine Recipe-ID vorhanden.';
  end if;

  -- Personal Today may only contain a recipe the current user owns or has
  -- explicitly saved. No target-user parameter is accepted by this RPC.
  select r.servings
    into base_servings
  from public.recipes r
  where r.id = p_recipe_id
    and (
      r.created_by = uid
      or exists (
        select 1
        from public.recipe_saves rs
        where rs.recipe_id = r.id
          and rs.user_id = uid
      )
    );

  if base_servings is null then
    raise exception 'Rezept ist nicht verfügbar.';
  end if;

  target_servings := coalesce(p_servings, base_servings);
  if target_servings < 1 or target_servings > 12 then
    raise exception 'Ungültige Personenzahl.';
  end if;

  -- Lock the active personal plan for this user/day so two rapid taps cannot
  -- create competing state while the shopping list is rebuilt.
  select p.id, p.recipe_id
    into pid, previous_recipe
  from public.personal_today_plans p
  where p.user_id = uid
    and p.plan_date = current_date
    and p.status <> 'cancelled'
  limit 1
  for update;

  if pid is null then
    insert into public.personal_today_plans(
      user_id,
      recipe_id,
      decision_type,
      decision_value,
      plan_date,
      status,
      servings
    )
    values(
      uid,
      p_recipe_id,
      'recipe',
      null,
      current_date,
      'planned',
      target_servings
    )
    returning id into pid;
    action_name := 'selected';
  else
    update public.personal_today_plans
    set recipe_id = p_recipe_id,
        decision_type = 'recipe',
        decision_value = null,
        status = 'planned',
        servings = target_servings,
        updated_at = now()
    where id = pid
      and user_id = uid;

    action_name := case
      when previous_recipe is distinct from p_recipe_id then 'replaced'
      else 'selected'
    end;
  end if;

  delete from public.shopping_items
  where personal_today_plan_id = pid
    and source = 'recipe';

  insert into public.shopping_items(
    personal_today_plan_id,
    food_id,
    name,
    quantity,
    unit,
    source
  )
  select
    pid,
    ri.food_id,
    ri.name,
    round(
      (ri.quantity * target_servings::numeric /
        greatest(base_servings, 1))::numeric,
      2
    ),
    ri.unit,
    'recipe'
  from public.recipe_ingredients ri
  where ri.recipe_id = p_recipe_id;

  insert into public.personal_decision_history(
    user_id,
    plan_id,
    recipe_id,
    action,
    source
  )
  values(
    uid,
    pid,
    p_recipe_id,
    action_name,
    'today'
  );

  return pid;
end;
$$;

revoke all on function public.set_personal_today_plan(uuid, integer) from public, anon;
grant execute on function public.set_personal_today_plan(uuid, integer) to authenticated;
