-- Technical audit: add covering indexes for foreign keys reported by
-- Supabase performance advisors.
create index if not exists idx_personal_decision_history_plan_id
  on public.personal_decision_history (plan_id);

create index if not exists idx_personal_today_plans_recipe_id
  on public.personal_today_plans (recipe_id);
