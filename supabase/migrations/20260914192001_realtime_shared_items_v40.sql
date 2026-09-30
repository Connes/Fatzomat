-- Live in-app updates for the two-person experience.
do $$ begin
  alter publication supabase_realtime add table public.app_notifications;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.shopping_items;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.shared_recipe_plans;
exception when duplicate_object then null; end $$;
