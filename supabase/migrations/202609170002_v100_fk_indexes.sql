-- V1.0 performance hardening: cover foreign keys used by collaboration,
-- notifications and shopping flows.
create index if not exists app_notifications_recipe_id_idx
  on public.app_notifications(recipe_id);
create index if not exists app_notifications_shared_recipe_plan_id_idx
  on public.app_notifications(shared_recipe_plan_id);
create index if not exists connections_created_by_idx
  on public.connections(created_by);
create index if not exists shared_recipe_plans_recipe_id_idx
  on public.shared_recipe_plans(recipe_id);
create index if not exists shared_recipe_plans_shared_by_idx
  on public.shared_recipe_plans(shared_by);
create index if not exists shopping_items_checked_by_idx
  on public.shopping_items(checked_by);
create index if not exists shopping_items_food_id_idx
  on public.shopping_items(food_id);
