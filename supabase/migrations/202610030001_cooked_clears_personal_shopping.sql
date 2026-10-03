create or replace function public.update_personal_today_status(p_plan_id uuid, p_status text)
returns boolean
language plpgsql
set search_path to 'public', 'pg_temp'
as $function$
declare
  changed integer;
  uid uuid := auth.uid();
  rid uuid;
begin
  if uid is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  if p_status not in ('planned','shopping','cooked','cancelled') then
    raise exception 'Ungültiger Status.';
  end if;

  select recipe_id
    into rid
  from public.personal_today_plans p
  where p.id = p_plan_id
    and p.user_id = uid
    and p.plan_date = current_date
    and p.status <> 'cancelled';

  if not found then
    raise exception 'Persönlicher Tagesplan ist nicht verfügbar.';
  end if;

  if p_status = 'cooked' then
    delete from public.shopping_items
    where personal_today_plan_id = p_plan_id;
  end if;

  update public.personal_today_plans
  set status = p_status,
      updated_at = now()
  where id = p_plan_id
    and user_id = uid
    and plan_date = current_date;

  get diagnostics changed = row_count;

  if changed = 1 then
    insert into public.personal_decision_history(user_id, plan_id, recipe_id, action, source)
    values(
      uid,
      p_plan_id,
      rid,
      case when p_status = 'cancelled' then 'cancelled' else 'status_changed' end,
      'today'
    );
  end if;

  return changed = 1;
end;
$function$;