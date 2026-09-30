-- Cleanup round: indexes supporting the user-centric collection and shared-day flows.
create index if not exists idx_recipe_saves_user_saved_at
  on public.recipe_saves (user_id, saved_at desc);

create index if not exists idx_shared_recipe_plans_plan_date_status
  on public.shared_recipe_plans (plan_date, status);

create index if not exists idx_shopping_items_plan_checked
  on public.shopping_items (shared_recipe_plan_id, checked);
