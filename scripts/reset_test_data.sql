-- Fatzomat development/test reset for the current schema.
-- DESTRUCTIVE: this removes every auth user and all user-owned data.
-- Execute only against the dedicated development/test Supabase project.
-- Never run against production.
--
-- Example:
-- psql "$TEST_DATABASE_URL" -v TEST_RESET_CONFIRM=FATZOMAT_TEST_RESET -f scripts/reset_test_data.sql
--
-- The explicit confirmation is mandatory. The script does not create a backup.

\\if :{?TEST_RESET_CONFIRM}
\\else
\\echo 'TEST_RESET_CONFIRM is required. Nothing was changed.'
\\quit
\\endif

\\if :TEST_RESET_CONFIRM = 'FATZOMAT_TEST_RESET'
\\else
\\echo 'Wrong confirmation. Nothing was changed.'
\\quit
\\endif

BEGIN;

-- Remember recipe image paths before removing user-created recipes. Recipe
-- images live in Storage and are not removed automatically by deleting a row.
CREATE TEMP TABLE reset_user_recipe_ids ON COMMIT DROP AS
SELECT id::text AS recipe_id
FROM public.recipes
WHERE created_by IS NOT NULL;

-- Remove private image files belonging to user-created recipes. The bucket
-- and object metadata are kept intact; only matching objects are deleted.
DELETE FROM storage.objects o
WHERE o.bucket_id = 'recipe-images'
  AND split_part(o.name, '/', 1) IN (
    SELECT recipe_id FROM reset_user_recipe_ids
  );

-- Remove all user-owned and connection-related application data. CASCADE is
-- intentional for dependent rows (including recipe deletion requests).
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

-- Recipe deletion requests are user-specific. This explicit delete also
-- covers deployments where the table is not reached through TRUNCATE CASCADE.
DELETE FROM public.recipe_deletion_requests;

-- Recipes are a global application library. Preserve seed/library entries
-- (created_by IS NULL); remove all user-created recipes and their ingredients.
DELETE FROM public.recipes
WHERE created_by IS NOT NULL;

-- Delete users last. Supabase Auth cascades identities, sessions, refresh
-- tokens, and other auth-owned records through its foreign keys.
DELETE FROM auth.users;

COMMIT;

-- Verification: all user records and user-created recipe records must be gone.
-- Seed/global recipes and food catalog data are intentionally preserved.
SELECT
  (SELECT count(*) FROM auth.users) AS auth_user_count,
  (SELECT count(*) FROM public.profiles) AS profile_count,
  (SELECT count(*) FROM public.connections) AS connection_count,
  (SELECT count(*) FROM public.connection_members) AS connection_member_count,
  (SELECT count(*) FROM public.personal_today_plans) AS personal_plan_count,
  (SELECT count(*) FROM public.shared_recipe_plans) AS shared_plan_count,
  (SELECT count(*) FROM public.shopping_items) AS shopping_item_count,
  (SELECT count(*) FROM public.user_food_preferences) AS food_preference_count,
  (SELECT count(*) FROM public.recipe_saves) AS recipe_save_count,
  (SELECT count(*) FROM public.recipe_suggestions) AS recipe_suggestion_count,
  (SELECT count(*) FROM public.decision_requests) AS decision_request_count,
  (SELECT count(*) FROM public.decision_shares) AS decision_share_count,
  (SELECT count(*) FROM public.push_devices) AS push_device_count,
  (SELECT count(*) FROM public.app_notifications) AS notification_count,
  (SELECT count(*) FROM public.recipe_deletion_requests) AS recipe_deletion_request_count,
  (SELECT count(*) FROM public.recipes WHERE created_by IS NOT NULL) AS user_created_recipe_count,
  (SELECT count(*) FROM storage.objects WHERE bucket_id = 'recipe-images') AS remaining_recipe_image_object_count;
