-- V48: make the Today workflow deterministic while allowing a cancelled plan
-- to be replaced later on the same day.
alter table public.shared_recipe_plans
  drop constraint if exists shared_recipe_plans_connection_id_plan_date_key;

create unique index if not exists shared_recipe_plans_one_active_per_connection_day
  on public.shared_recipe_plans(connection_id, plan_date)
  where status <> 'cancelled';
