-- Reserve AI generation quota with a server-generated event id so failed
-- The preceding security migration changed this function's return type;
-- PostgreSQL requires an explicit drop before replacing it with bigint.
drop function if exists public.consume_ai_generation_quota();
-- generations can release the reservation again. Limits remain server-owned.

create or replace function public.consume_ai_generation_quota()
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_event_id bigint;
  v_hourly_count integer;
  v_daily_count integer;
begin
  if v_user_id is null then
    raise exception 'Nicht authentifiziert.' using errcode = '42501';
  end if;

  select count(*) into v_hourly_count
  from public.ai_generation_events
  where user_id = v_user_id
    and created_at >= now() - interval '1 hour';

  if v_hourly_count >= 5 then
    raise exception 'KI-Limit pro Stunde erreicht.' using errcode = 'P0001';
  end if;

  select count(*) into v_daily_count
  from public.ai_generation_events
  where user_id = v_user_id
    and created_at >= now() - interval '24 hours';

  if v_daily_count >= 20 then
    raise exception 'KI-Limit pro Tag erreicht.' using errcode = 'P0001';
  end if;

  insert into public.ai_generation_events (user_id)
  values (v_user_id)
  returning id into v_event_id;

  return v_event_id;
end;
$$;

create or replace function public.release_ai_generation_quota(p_event_id bigint)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Nicht authentifiziert.' using errcode = '42501';
  end if;

  delete from public.ai_generation_events
  where id = p_event_id
    and user_id = auth.uid();

  return found;
end;
$$;

revoke all on function public.consume_ai_generation_quota() from public, anon;
grant execute on function public.consume_ai_generation_quota() to authenticated;

revoke all on function public.release_ai_generation_quota(bigint) from public, anon;
grant execute on function public.release_ai_generation_quota(bigint) to authenticated;
