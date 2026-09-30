select plan(1);

-- Run against a disposable Supabase database after migrations.
-- No test users are created. Checks current schema/security invariants.

do $$
begin
  if to_regclass('public.ai_generation_events') is not null then
    raise exception 'Retired AI generation event table still exists';
  end if;
  if to_regprocedure('public.consume_ai_generation_quota()') is not null then
    raise exception 'Retired parameterless AI quota RPC still exists';
  end if;
  if to_regprocedure('public.consume_ai_generation_quota(integer,integer)') is not null then
    raise exception 'Retired client-controlled AI quota RPC still exists';
  end if;
  if to_regprocedure('public.release_ai_generation_quota(bigint)') is not null then
    raise exception 'Retired AI quota rollback RPC still exists';
  end if;
end $$;

do $$
begin
  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef = true
      and not (coalesce(p.proconfig, ARRAY[]::text[]) @> ARRAY['search_path=public'])
  ) then
    raise exception 'Found SECURITY DEFINER function without search_path=public: %', (select string_agg(n.nspname || '.' || p.proname || '/' || p.oid::text, ', ') from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.prosecdef = true and not (coalesce(p.proconfig, ARRAY[]::text[]) @> ARRAY['search_path=public']));
  end if;

  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef = true
      and has_function_privilege('anon', p.oid, 'EXECUTE')
  ) then
    raise exception 'Found SECURITY DEFINER function executable by anon';
  end if;
end $$;

do $$
begin
  if to_regclass('public.personal_today_plans') is null then
    raise exception 'Personal TodayPlan table is missing';
  end if;
  if to_regclass('public.shopping_items') is null then
    raise exception 'Shopping items table is missing';
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='shopping_items' and column_name='personal_today_plan_id'
  ) then
    raise exception 'Personal shopping ownership column is missing';
  end if;
  if to_regprocedure('public.set_personal_today_plan(uuid,integer)') is null then
    raise exception 'Personal TodayPlan RPC is missing';
  end if;
  if to_regprocedure('public.update_personal_today_plan_servings(uuid,integer)') is null then
    raise exception 'Personal TodayPlan servings RPC is missing';
  end if;
  if to_regprocedure('public.cancel_personal_today_plan(uuid)') is null then
    raise exception 'Personal TodayPlan cancel RPC is missing';
  end if;
  if to_regprocedure('public.update_personal_today_status(uuid,text)') is null then
    raise exception 'Personal TodayPlan status RPC is missing';
  end if;
end $$;

do $$
begin
  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in ('set_personal_today_plan','update_personal_today_plan_servings','cancel_personal_today_plan','update_personal_today_status')
      and p.prosecdef = true
  ) then
    raise exception 'Personal TodayPlan RPC must use SECURITY INVOKER';
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_indexes
    where schemaname = 'public'
      and indexname = 'idx_personal_decision_history_plan_id'
  ) then
    raise exception 'Missing personal_decision_history.plan_id index';
  end if;

  if not exists (
    select 1 from pg_indexes
    where schemaname = 'public'
      and indexname = 'idx_personal_today_plans_recipe_id'
  ) then
    raise exception 'Missing personal_today_plans.recipe_id index';
  end if;
end $$;


select pass(1, 'schema and security invariants hold');
select * from finish();
