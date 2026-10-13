-- Persist shopping-list completion independently from meal completion.
alter table public.personal_today_plans
  add column if not exists shopping_list_completed_at timestamptz;

create or replace function public.complete_personal_shopping_list(p_plan_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_counterpart_plan_id uuid;
  v_completed_at timestamptz := now();
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  update public.personal_today_plans
  set shopping_list_completed_at = coalesce(shopping_list_completed_at, v_completed_at),
      updated_at = now()
  where id = p_plan_id
    and user_id = v_user_id;

  if not found then
    raise exception 'Shopping list plan not found or not owned by current user';
  end if;

  select case
    when ds.source_plan_id = p_plan_id then ds.accepted_plan_id
    else ds.source_plan_id
  end
  into v_counterpart_plan_id
  from public.decision_shares ds
  where ds.message_type = 'share'
    and ds.cancelled_at is null
    and ds.accepted_at is not null
    and ds.source_plan_id is not null
    and ds.accepted_plan_id is not null
    and (ds.source_plan_id = p_plan_id or ds.accepted_plan_id = p_plan_id)
  order by ds.created_at desc
  limit 1;

  if v_counterpart_plan_id is not null then
    update public.personal_today_plans
    set shopping_list_completed_at = coalesce(shopping_list_completed_at, v_completed_at),
        updated_at = now()
    where id = v_counterpart_plan_id;
  end if;

  return true;
end;
$$;

revoke all on function public.complete_personal_shopping_list(uuid) from public, anon;
grant execute on function public.complete_personal_shopping_list(uuid) to authenticated;
