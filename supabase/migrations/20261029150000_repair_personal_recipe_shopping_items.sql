-- Repair missing shopping rows for a personal recipe plan.
-- This is intentionally additive: checked rows and manual edits are preserved.
CREATE OR REPLACE FUNCTION public.ensure_personal_recipe_shopping_items(
  p_plan_id uuid
) RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  uid uuid := auth.uid();
  plan_row public.personal_today_plans%ROWTYPE;
  base_servings integer;
  inserted_count integer;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Keine Supabase-Sitzung vorhanden.';
  END IF;

  SELECT *
    INTO plan_row
    FROM public.personal_today_plans
   WHERE id = p_plan_id
     AND user_id = uid
     AND status = 'planned'
     AND decision_type = 'recipe'
     AND recipe_id IS NOT NULL
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Kein aktiver persönlicher Rezeptplan gefunden.';
  END IF;

  SELECT greatest(coalesce(r.servings, 1), 1)
    INTO base_servings
    FROM public.recipes r
   WHERE r.id = plan_row.recipe_id;

  IF base_servings IS NULL THEN
    RAISE EXCEPTION 'Rezept ist nicht verfügbar.';
  END IF;

  INSERT INTO public.shopping_items (
    personal_today_plan_id, food_id, name, quantity, unit, source
  )
  SELECT
    plan_row.id,
    ingredients.food_id,
    ingredients.name,
    round(
      (coalesce(ingredients.quantity, 0) * plan_row.servings::numeric
        / base_servings::numeric)::numeric,
      2
    ),
    ingredients.unit,
    'recipe'
  FROM (
    SELECT
      ri.recipe_id,
      ri.food_id,
      ri.name,
      min(ri.unit) AS unit,
      sum(coalesce(ri.quantity, 0)) AS quantity
    FROM public.recipe_ingredients ri
    WHERE ri.recipe_id = plan_row.recipe_id
    GROUP BY ri.recipe_id, ri.food_id, ri.name, lower(coalesce(ri.unit, ''))
  ) AS ingredients
  WHERE NOT EXISTS (
    SELECT 1
      FROM public.shopping_items si
     WHERE si.personal_today_plan_id = plan_row.id
       AND si.source = 'recipe'
       AND si.name = ingredients.name
       AND coalesce(si.food_id::text, '') = coalesce(ingredients.food_id::text, '')
       AND lower(coalesce(si.unit, '')) = lower(coalesce(ingredients.unit, ''))
  );

  GET DIAGNOSTICS inserted_count = ROW_COUNT;
  RETURN inserted_count;
END;
$function$;

REVOKE ALL ON FUNCTION public.ensure_personal_recipe_shopping_items(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.ensure_personal_recipe_shopping_items(uuid) TO authenticated;
