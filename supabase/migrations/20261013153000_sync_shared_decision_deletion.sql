-- Delete the linked personal copy when either side deletes an accepted shared decision.
-- Mark the share cancelled before deleting the counterpart so the nested DELETE
-- trigger is idempotent and does not delete unrelated plans.
create or replace function public.sync_shared_decision_deletion()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  counterpart_plan_ids uuid[];
begin
  select array_agg(
    case
      when ds.source_plan_id = old.id then ds.accepted_plan_id
      else ds.source_plan_id
    end
  )
  into counterpart_plan_ids
  from public.decision_shares ds
  where ds.message_type = 'share'
    and ds.cancelled_at is null
    and ds.source_plan_id is not null
    and ds.accepted_plan_id is not null
    and (ds.source_plan_id = old.id or ds.accepted_plan_id = old.id);

  if coalesce(array_length(counterpart_plan_ids, 1), 0) > 0 then
    -- Break the active relationship before deleting the counterpart. Its own
    -- BEFORE DELETE trigger invocation will then find no active share.
    update public.decision_shares ds
    set cancelled_at = now(),
        cancelled_by = coalesce(ds.cancelled_by, auth.uid())
    where ds.message_type = 'share'
      and ds.cancelled_at is null
      and ds.source_plan_id is not null
      and ds.accepted_plan_id is not null
      and (ds.source_plan_id = old.id or ds.accepted_plan_id = old.id);

    delete from public.personal_today_plans p
    where p.id = any(counterpart_plan_ids)
      and p.id <> old.id;
  end if;

  return old;
end;
$$;

drop trigger if exists sync_shared_decision_deletion
  on public.personal_today_plans;

create trigger sync_shared_decision_deletion
before delete on public.personal_today_plans
for each row
execute function public.sync_shared_decision_deletion();

revoke all on function public.sync_shared_decision_deletion() from public, anon, authenticated;
