-- Date-aware personal meal planning.
-- Existing RPCs remain available for older clients; new clients pass an explicit local calendar date.
CREATE OR REPLACE FUNCTION public.set_personal_plan_for_date(
  p_plan_date date,
  p_decision_type text,
  p_decision_value text DEFAULT NULL,
  p_recipe_id uuid DEFAULT NULL,
  p_servings integer DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  uid uuid := auth.uid();
  pid uuid;
  base_servings integer;
  target_servings integer;
  normalized_type text := lower(trim(p_decision_type));
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'Keine Supabase-Sitzung vorhanden.'; END IF;
  IF p_plan_date IS NULL THEN RAISE EXCEPTION 'Kein Planungsdatum angegeben.'; END IF;
  IF normalized_type NOT IN ('recipe', 'order', 'dine_out', 'surprise') THEN
    RAISE EXCEPTION 'Ungültiger persönlicher Entscheidungstyp.';
  END IF;
  IF normalized_type = 'recipe' THEN
    IF p_recipe_id IS NULL THEN RAISE EXCEPTION 'Keine Recipe-ID vorhanden.'; END IF;
    SELECT servings INTO base_servings FROM public.recipes WHERE id = p_recipe_id;
    IF base_servings IS NULL THEN RAISE EXCEPTION 'Rezept ist nicht verfügbar.'; END IF;
    target_servings := coalesce(p_servings, base_servings);
    IF target_servings < 1 OR target_servings > 12 THEN RAISE EXCEPTION 'Ungültige Personenzahl.'; END IF;
  ELSE
    IF coalesce(trim(p_decision_value), '') = '' THEN RAISE EXCEPTION 'Die Auswahl darf nicht leer sein.'; END IF;
    target_servings := 1;
  END IF;

  -- One open decision per user and day; completed decisions remain as history.
  SELECT id INTO pid FROM public.personal_today_plans
  WHERE user_id = uid AND plan_date = p_plan_date AND status = 'planned'
  ORDER BY created_at DESC LIMIT 1;

  IF pid IS NULL THEN
    INSERT INTO public.personal_today_plans(user_id, recipe_id, decision_type, decision_value, plan_date, status, servings)
    VALUES(uid, CASE WHEN normalized_type = 'recipe' THEN p_recipe_id ELSE NULL END,
      normalized_type, CASE WHEN normalized_type = 'recipe' THEN NULL ELSE trim(p_decision_value) END,
      p_plan_date, 'planned', target_servings)
    RETURNING id INTO pid;
  ELSE
    UPDATE public.personal_today_plans
      SET recipe_id = CASE WHEN normalized_type = 'recipe' THEN p_recipe_id ELSE NULL END,
          decision_type = normalized_type,
          decision_value = CASE WHEN normalized_type = 'recipe' THEN NULL ELSE trim(p_decision_value) END,
          servings = target_servings, updated_at = now()
      WHERE id = pid AND user_id = uid;
  END IF;

  DELETE FROM public.shopping_items WHERE personal_today_plan_id = pid AND source = 'recipe';
  IF normalized_type = 'recipe' THEN
    INSERT INTO public.shopping_items(personal_today_plan_id, food_id, name, quantity, unit, source)
    SELECT pid, ri.food_id, ri.name,
      round((ri.quantity * target_servings::numeric / greatest(base_servings, 1))::numeric, 2),
      ri.unit, 'recipe'
    FROM public.recipe_ingredients ri WHERE ri.recipe_id = p_recipe_id;
  END IF;
  RETURN pid;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.set_personal_plan_for_date(date, text, text, uuid, integer) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_personal_plans_for_date(p_plan_date date)
RETURNS SETOF public.personal_today_plans
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path TO 'public', 'pg_temp'
AS $function$
  SELECT p.* FROM public.personal_today_plans p
  WHERE p.user_id = auth.uid() AND p.plan_date = p_plan_date
  ORDER BY p.created_at DESC;
$function$;
GRANT EXECUTE ON FUNCTION public.get_personal_plans_for_date(date) TO authenticated;
