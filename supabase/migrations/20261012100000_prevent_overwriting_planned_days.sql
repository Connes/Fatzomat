-- Selecting a recipe from the library must never silently replace an
-- existing personal or shared meal decision for the same date.
CREATE OR REPLACE FUNCTION public.set_personal_plan_for_date(
  p_plan_date date,
  p_decision_type text,
  p_decision_value text DEFAULT NULL,
  p_recipe_id uuid DEFAULT NULL,
  p_servings integer DEFAULT NULL
)
RETURNS uuid
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
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Keine Supabase-Sitzung vorhanden.';
  END IF;
  IF p_plan_date IS NULL THEN
    RAISE EXCEPTION 'Kein Planungsdatum angegeben.';
  END IF;
  IF normalized_type IS NULL OR normalized_type NOT IN ('recipe', 'order', 'dine_out', 'surprise') THEN
    RAISE EXCEPTION 'Ungültiger persönlicher Entscheidungstyp.';
  END IF;

  IF normalized_type = 'recipe' THEN
    IF p_recipe_id IS NULL THEN
      RAISE EXCEPTION 'Keine Recipe-ID vorhanden.';
    END IF;
    SELECT greatest(coalesce(r.servings, 1), 1)
      INTO base_servings
      FROM public.recipes r
      WHERE r.id = p_recipe_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Rezept ist nicht verfügbar.';
    END IF;
    target_servings := coalesce(p_servings, base_servings);
    IF target_servings < 1 OR target_servings > 12 THEN
      RAISE EXCEPTION 'Ungültige Personenzahl.';
    END IF;
  ELSE
    IF coalesce(trim(p_decision_value), '') = '' THEN
      RAISE EXCEPTION 'Die Auswahl darf nicht leer sein.';
    END IF;
    target_servings := 1;
  END IF;

  -- Serialize selections for a user/date before checking availability.
  PERFORM pg_advisory_xact_lock(hashtext(uid::text), hashtext(p_plan_date::text));

  SELECT id INTO pid
  FROM public.personal_today_plans
  WHERE user_id = uid
    AND plan_date = p_plan_date
    AND status = 'planned'
  ORDER BY created_at DESC
  LIMIT 1;

  IF pid IS NOT NULL THEN
    RAISE EXCEPTION 'Dieser Tag ist bereits verplant. Bitte wähle einen freien Tag.';
  END IF;

  -- Shared plans are stored separately from personal decisions. They still
  -- occupy the same day for members of the connection.
  IF EXISTS (
    SELECT 1
    FROM public.shared_recipe_plans srp
    WHERE srp.plan_date = p_plan_date
      AND srp.status = 'planned'
      AND public.is_connection_member(srp.connection_id)
  ) THEN
    RAISE EXCEPTION 'An diesem Tag ist bereits ein gemeinsamer Essensplan eingetragen.';
  END IF;

  INSERT INTO public.personal_today_plans(
    user_id, recipe_id, decision_type, decision_value, plan_date, status, servings
  )
  VALUES (
    uid,
    CASE WHEN normalized_type = 'recipe' THEN p_recipe_id ELSE NULL END,
    normalized_type,
    CASE WHEN normalized_type = 'recipe' THEN NULL ELSE trim(p_decision_value) END,
    p_plan_date,
    'planned',
    target_servings
  )
  RETURNING id INTO pid;

  IF normalized_type = 'recipe' THEN
    INSERT INTO public.shopping_items(
      personal_today_plan_id, food_id, name, quantity, unit, source
    )
    SELECT
      pid,
      ri.food_id,
      ri.name,
      round((ri.quantity * target_servings::numeric / greatest(base_servings, 1))::numeric, 2),
      ri.unit,
      'recipe'
    FROM public.recipe_ingredients ri
    WHERE ri.recipe_id = p_recipe_id;
  END IF;

  RETURN pid;
END;
$function$;

REVOKE ALL ON FUNCTION public.set_personal_plan_for_date(date, text, text, uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_personal_plan_for_date(date, text, text, uuid, integer) TO authenticated;
