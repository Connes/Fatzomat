-- Ensure accepting a shared recipe always creates the shared plan and its
-- shopping items, even if the recipient already has a personal decision for
-- that date. The existing personal decision is left intact in that case.
create or replace function public.accept_decision_share(p_share_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  share_row public.decision_shares;
  source_recipe public.recipes;
  personal_plan_id uuid;
  shared_plan_id uuid;
  sender_name text;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;

  select * into share_row
  from public.decision_shares
  where id = p_share_id
    and recipient_id = uid
    and public.is_connection_member(connection_id)
  for update;

  if share_row.id is null then raise exception 'Die geteilte Entscheidung ist nicht mehr verfügbar.'; end if;
  if share_row.message_type <> 'share' then raise exception 'Diese Nachricht enthält keine übernehmbare Entscheidung.'; end if;
  if share_row.cancelled_at is not null then raise exception 'Diese gemeinsame Entscheidung wurde bereits entfernt.'; end if;
  if share_row.plan_date < current_date then raise exception 'Der Tag dieser geteilten Entscheidung ist bereits vergangen.'; end if;
  if share_row.rejected_at is not null then raise exception 'Die geteilte Entscheidung wurde bereits abgelehnt.'; end if;

  if share_row.accepted_at is not null and share_row.shared_recipe_plan_id is not null then
    return jsonb_build_object(
      'share_id', share_row.id, 'plan_id', share_row.accepted_plan_id,
      'decision_type', share_row.decision_type, 'recipe_id', share_row.accepted_recipe_id,
      'shared_recipe_plan_id', share_row.shared_recipe_plan_id
    );
  end if;

  if share_row.decision_type = 'recipe' then
    if share_row.recipe_id is null then raise exception 'Das geteilte Rezept ist nicht mehr verfügbar.'; end if;
    select * into source_recipe from public.recipes where id = share_row.recipe_id for share;
    if source_recipe.id is null then raise exception 'Das geteilte Rezept ist nicht mehr verfügbar.'; end if;

    -- Do not let a pre-existing personal plan abort acceptance. Reuse it only
    -- when it already represents the accepted recipe; otherwise preserve it
    -- and still create the shared plan.
    select id into personal_plan_id
    from public.personal_today_plans
    where user_id = uid
      and plan_date = share_row.plan_date
      and status = 'planned'
    order by created_at desc
    limit 1;

    if personal_plan_id is not null then
      if not exists (
        select 1 from public.personal_today_plans
        where id = personal_plan_id and decision_type = 'recipe'
          and recipe_id = share_row.recipe_id
      ) then
        personal_plan_id := null;
      end if;
    else
      -- This must happen before creating shared_recipe_plans because the
      -- personal-plan RPC correctly rejects dates already occupied by a
      -- shared plan.
      personal_plan_id := public.set_personal_plan_for_date(
        share_row.plan_date, 'recipe', null, share_row.recipe_id, share_row.servings
      );
    end if;

    select id into shared_plan_id
    from public.shared_recipe_plans
    where connection_id = share_row.connection_id
      and plan_date = share_row.plan_date
      and status <> 'cancelled'
    order by created_at desc limit 1;

    if shared_plan_id is null then
      insert into public.shared_recipe_plans(connection_id,recipe_id,shared_by,plan_date,status,servings)
      values (share_row.connection_id,share_row.recipe_id,share_row.sender_id,share_row.plan_date,'planned',share_row.servings)
      returning id into shared_plan_id;

      insert into public.shopping_items(shared_recipe_plan_id,food_id,name,quantity,unit,source)
      select shared_plan_id,ri.food_id,ri.name,
        round((ri.quantity * share_row.servings::numeric / greatest(source_recipe.servings,1))::numeric,2),
        ri.unit,'recipe'
      from public.recipe_ingredients ri where ri.recipe_id = share_row.recipe_id;
    end if;

    update public.decision_shares
    set accepted_at = coalesce(accepted_at, now()),
        accepted_plan_id = personal_plan_id,
        accepted_recipe_id = share_row.recipe_id,
        shared_recipe_plan_id = shared_plan_id
    where id = share_row.id;
  elsif share_row.decision_type in ('order','dine_out','surprise') then
    if nullif(btrim(share_row.decision_value),'') is null then
      raise exception 'Die geteilte Entscheidung ist nicht mehr vollständig verfügbar.';
    end if;
    select id into personal_plan_id
    from public.personal_today_plans
    where user_id = uid and plan_date = share_row.plan_date and status = 'planned'
    order by created_at desc limit 1;

    if personal_plan_id is null then
      personal_plan_id := public.set_personal_plan_for_date(
        share_row.plan_date, share_row.decision_type, share_row.decision_value, null, null
      );
    end if;

    update public.decision_shares
    set accepted_at = coalesce(accepted_at, now()), accepted_plan_id = personal_plan_id
    where id = share_row.id;
  else
    raise exception 'Ungültige geteilte Entscheidung.';
  end if;

  select nullif(btrim(display_name),'') into sender_name from public.profiles where id = uid;
  insert into public.app_notifications(user_id,type,title,body,decision_share_id)
  values (
    share_row.sender_id, 'decision_message_response', 'Entscheidung übernommen',
    coalesce(sender_name,'Deine verbundene Person') || ' hat deine geteilte Entscheidung für ' ||
      to_char(share_row.plan_date, 'DD.MM.YYYY') || ' übernommen.',
    share_row.id
  );

  return jsonb_build_object(
    'share_id', share_row.id, 'plan_id', personal_plan_id,
    'decision_type', share_row.decision_type,
    'recipe_id', share_row.recipe_id, 'shared_recipe_plan_id', shared_plan_id
  );
end;
$$;

revoke all on function public.accept_decision_share(uuid) from public, anon;
grant execute on function public.accept_decision_share(uuid) to authenticated;

notify pgrst, 'reload schema';
