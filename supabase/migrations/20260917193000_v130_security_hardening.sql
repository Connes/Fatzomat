-- V1.3 security hardening: make AI quota limits server-owned and close trigger/RLS audit gaps.

drop function if exists public.consume_ai_generation_quota(integer, integer);
create or replace function public.consume_ai_generation_quota()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  hourly_count integer;
  daily_count integer;
  hourly_limit constant integer := 5;
  daily_limit constant integer := 20;
begin
  if uid is null then
    raise exception 'Nicht authentifiziert.' using errcode = '28000';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(uid::text, 0));
  delete from public.ai_generation_events
  where user_id = uid and created_at < now() - interval '30 days';
  select count(*) into hourly_count from public.ai_generation_events
    where user_id = uid and created_at >= now() - interval '1 hour';
  if hourly_count >= hourly_limit then
    raise exception 'KI-Limit erreicht. Bitte später erneut versuchen.' using errcode = 'P0001';
  end if;
  select count(*) into daily_count from public.ai_generation_events
    where user_id = uid and created_at >= now() - interval '24 hours';
  if daily_count >= daily_limit then
    raise exception 'Tageslimit für KI-Rezeptvorschläge erreicht.' using errcode = 'P0001';
  end if;
  insert into public.ai_generation_events(user_id) values (uid);
  return true;
end;
$$;

revoke all on function public.consume_ai_generation_quota() from public, anon;
grant execute on function public.consume_ai_generation_quota() to authenticated;

revoke execute on function public.handle_new_user() from public, anon, authenticated;
grant execute on function public.handle_new_user() to service_role;

drop policy if exists "ai generation events deny client access" on public.ai_generation_events;
create policy "ai generation events deny client access"
on public.ai_generation_events for all to authenticated
using (false) with check (false);

revoke all on table public.ai_generation_events from anon, authenticated, public;
