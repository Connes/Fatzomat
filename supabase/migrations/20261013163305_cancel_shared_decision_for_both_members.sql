-- Removing an accepted shared day decision must remove it for both
-- members, regardless of which member initiated the removal.
create or replace function public.cancel_shared_decision_for_plan(p_plan_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  share_row public.decision_shares;
begin
  if uid is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;
  if p_plan_id is null then
    raise exception 'Keine Entscheidungs-ID vorhanden.';
  end if;

  select ds.* into share_row
  from public.decision_shares ds
  where ds.message_type = 'share'
    and ds.accepted_at is not null
    and ds.cancelled_at is null
    and (ds.source_plan_id = p_plan_id or ds.accepted_plan_id = p_plan_id)
    and (ds.sender_id = uid or ds.recipient_id = uid)
    and public.is_connection_member(ds.connection_id)
  order by ds.created_at desc
  limit 1
  for update;

  if share_row.id is null then
    raise exception 'Keine aktive gemeinsame Tagesentscheidung zu diesem Plan gefunden.';
  end if;

  update public.decision_shares
  set cancelled_at = now(),
      cancelled_by = coalesce(cancelled_by, uid)
  where id = share_row.id;

  if share_row.shared_recipe_plan_id is not null then
    update public.shared_recipe_plans
    set status = 'cancelled'
    where id = share_row.shared_recipe_plan_id
      and status <> 'cancelled';

    delete from public.shopping_items
    where shared_recipe_plan_id = share_row.shared_recipe_plan_id;
  end if;

  update public.personal_today_plans
  set status = 'cancelled',
      updated_at = now()
  where id in (share_row.source_plan_id, share_row.accepted_plan_id)
    and status = 'planned';

  delete from public.shopping_items
  where personal_today_plan_id in (share_row.source_plan_id, share_row.accepted_plan_id);

  return true;
end;
$$;

revoke all on function public.cancel_shared_decision_for_plan(uuid) from public, anon;
grant execute on function public.cancel_shared_decision_for_plan(uuid) to authenticated;
notify pgrst, 'reload schema';
