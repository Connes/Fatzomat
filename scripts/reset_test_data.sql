-- Fatzomat development test reset
-- Execute only against the dedicated development/test project.
-- The caller must explicitly pass the confirmation variable TEST_RESET_CONFIRM=FATZOMAT_TEST_RESET.

\if :{?TEST_RESET_CONFIRM}
\else
\echo 'TEST_RESET_CONFIRM is required.'
\quit
\endif

\if :TEST_RESET_CONFIRM = 'FATZOMAT_TEST_RESET'
\else
\echo 'Wrong confirmation. Nothing was changed.'
\quit
\endif

BEGIN;

-- Clear user-owned test data first. Foreign keys remain valid.
TRUNCATE TABLE
  public.user_food_preferences,
  public.shopping_items,
  public.personal_decision_history,
  public.personal_today_plans,
  public.push_devices,
  public.app_notifications,
  public.recipe_saves,
  public.recipe_suggestions,
  public.decision_requests,
  public.decision_shares,
  public.shared_recipe_plans,
  public.connection_members,
  public.connections,
  public.profiles
  RESTART IDENTITY CASCADE;

-- Remove test-created recipes while preserving application seed data.
DELETE FROM public.recipes WHERE created_by IS NOT NULL;

-- Auth users are removed last so user-linked foreign keys can be validated first.
DELETE FROM auth.users;

COMMIT;

-- Verification
SELECT
  (SELECT count(*) FROM auth.users) AS user_count,
  (SELECT count(*) FROM public.personal_today_plans) AS today_plan_count,
  (SELECT count(*) FROM public.shopping_items) AS shopping_item_count,
  (SELECT count(*) FROM public.user_food_preferences) AS food_preference_count,
  (SELECT count(*) FROM public.recipes WHERE created_by IS NOT NULL) AS user_recipe_count;
