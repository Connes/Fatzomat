-- Allow serving changes for any planned personal date, while preserving checked recipe rows.
CREATE OR REPLACE FUNCTION public.update_personal_plan_servings(
  p_plan_id uuid,
  p_servings integer
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  uid uuid := auth.uid();
  plan_row public.personal_today_plans%ROWTYPE;
  base_servings integer;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'Keine Supabase-Sitzung vorhanden.'; END IF;
  IF p_servings IS NULL OR p_servings < 1 OR p_servings > 12 THEN
    RAISE EXCEPTION 'Ungültige Personenzahl.';
  END IF;

  SELECT * INTO plan_row
  FROM public.personal_today_plans
  WHERE id = p_plan_id AND user_id = uid AND status = 'planned'
  FOR UPDATE;
  IF NOT FOUND THEN RETURN false; END IF;
  IF plan_row.decision_type <> 'recipe' OR plan_row.recipe_id IS NULL THEN
    RAISE EXCEPTION 'Für diese Entscheidung können keine Portionen geändert werden.';
  END IF;

  SELECT greatest(coalesce(servings, 1), 1) INTO base_servings
  FROM public.recipes WHERE id = plan_row.recipe_id;
  IF base_servings IS NULL THEN RAISE EXCEPTION 'Rezept ist nicht verfügbar.'; END IF;

  -- Update matching rows in place so checked state and item IDs survive.
  UPDATE public.shopping_items si
  SET quantity = round((ri.quantity * p_servings::numeric / base_servings::numeric)::numeric, 2)
  FROM public.recipe_ingredients ri
  WHERE si.personal_today_plan_id = p_plan_id
    AND si.source = 'recipe'
    AND si.name = ri.name
    AND coalesce(si.food_id::text, '') = coalesce(ri.food_id::text, '')
    AND lower(coalesce(si.unit, '')) = lower(coalesce(ri.unit, ''))
    AND ri.recipe_id = plan_row.recipe_id;

  INSERT INTO public.shopping_items(personal_today_plan_id, food_id, name, quantity, unit, source)
  SELECT p_plan_id, ri.food_id, ri.name,
         round((ri.quantity * p_servings::numeric / base_servings::numeric)::numeric, 2),
         ri.unit, 'recipe'
  FROM public.recipe_ingredients ri
  WHERE ri.recipe_id = plan_row.recipe_id
    AND NOT EXISTS (
      SELECT 1 FROM public.shopping_items si
      WHERE si.personal_today_plan_id = p_plan_id
        AND si.source = 'recipe'
        AND si.name = ri.name
        AND coalesce(si.food_id::text, '') = coalesce(ri.food_id::text, '')
        AND lower(coalesce(si.unit, '')) = lower(coalesce(ri.unit, ''))
    );

  DELETE FROM public.shopping_items si
  WHERE si.personal_today_plan_id = p_plan_id
    AND si.source = 'recipe'
    AND NOT EXISTS (
      SELECT 1 FROM public.recipe_ingredients ri
      WHERE ri.recipe_id = plan_row.recipe_id
        AND ri.name = si.name
        AND coalesce(ri.food_id::text, '') = coalesce(si.food_id::text, '')
        AND lower(coalesce(ri.unit, '')) = lower(coalesce(si.unit, ''))
    );

  UPDATE public.personal_today_plans
  SET servings = p_servings, updated_at = now()
  WHERE id = p_plan_id AND user_id = uid;
  RETURN true;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.update_personal_plan_servings(uuid, integer) TO authenticated;
