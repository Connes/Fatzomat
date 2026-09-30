-- v10: vote summary and stronger source metadata.
create or replace function public.meal_request_vote_summary(p_request_id uuid)
returns table(yes_count integer, no_count integer, my_vote smallint)
language sql
stable
security definer
set search_path = public
as $$
  select
    coalesce(sum(case when v.vote = 1 then 1 else 0 end), 0)::integer,
    coalesce(sum(case when v.vote = -1 then 1 else 0 end), 0)::integer,
    max(case when v.user_id = auth.uid() then v.vote else null end)::smallint
  from public.meal_request_votes v
  join public.meal_requests r on r.id = v.request_id
  where v.request_id = p_request_id
    and public.is_household_member(r.household_id);
$$;

grant execute on function public.meal_request_vote_summary(uuid) to authenticated;
