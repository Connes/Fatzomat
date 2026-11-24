-- Allow metadata updates for a recipe already attached to the caller's personal plan.
-- The recipe SELECT policy exposes recipes referenced by that user's plan/history.
-- Keep INSERT stricter; recipe replacement itself goes through the validated RPC.
DROP POLICY IF EXISTS "personal today own update" ON public.personal_today_plans;

CREATE POLICY "personal today own update"
ON public.personal_today_plans
FOR UPDATE
TO authenticated
USING (user_id = (SELECT auth.uid()))
WITH CHECK (
  user_id = (SELECT auth.uid())
  AND (
    (
      decision_type = 'recipe'
      AND recipe_id IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM public.recipes r
        WHERE r.id = personal_today_plans.recipe_id
      )
    )
    OR (
      decision_type = ANY (ARRAY['order'::text, 'dine_out'::text, 'surprise'::text])
      AND recipe_id IS NULL
      AND COALESCE(TRIM(decision_value), '') <> ''
    )
  )
);
