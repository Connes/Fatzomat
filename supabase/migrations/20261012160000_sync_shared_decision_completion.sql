-- Keep a shared Today decision's completion state in sync across both personal copies.
-- Accepted shares link the sender's source plan and recipient's accepted plan.
-- Updating either copy to cooked updates the other copy as well. The second
-- trigger invocation is naturally idempotent because the counterpart is no
-- longer in the planned state.
create or replace function public.sync_shared_decision_completion()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  counterpart_plan_id uuid;
begin
  if new.status is distinct from old.status and new.status = 'cooked' then
    select case
      when ds.source_plan_id = new.id then ds.accepted_plan_id
      else ds.source_plan_id
    end
    into counterpart_plan_id
    from public.decision_shares ds
    where ds.message_type = 'share'
      and ds.cancelled_at is null
      and (ds.source_plan_id = new.id or ds.accepted_plan_id = new.id)
    order by ds.created_at desc
    limit 1;

    if counterpart_plan_id is not null then
      update public.personal_today_plans
      set status = 'cooked',
          updated_at = now()
      where id = counterpart_plan_id
        and status = 'planned';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists sync_shared_decision_completion
  on public.personal_today_plans;

create trigger sync_shared_decision_completion
after update of status on public.personal_today_plans
for each row
when (old.status is distinct from new.status and new.status = 'cooked')
execute function public.sync_shared_decision_completion();

revoke all on function public.sync_shared_decision_completion() from public, anon, authenticated;
