-- Explicitly replace the current user's existing decision for a date.
-- Normal planning continues to use set_personal_plan_for_date, which rejects
-- occupied dates. This RPC is only called from the edit action on Today.
CREATE OR REPLACE FUNCTION public.replace_personal_plan_for_date(
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
  IF normalized_type IS NULL OR normalized_type NOT IN ('recipe', 'order', 'dine_out', 'surprise') THEN
    RAISE EXCEPTION 'Ungültiger persönlicher Entscheidungstyp.';
  END IF;

  IF normalized_type = 'recipe' THEN
    IF p_recipe_id IS NULL THEN RAISE EXCEPTION 'Keine Recipe-ID vorhanden.'; END IF;
    SELECT greatest(coalesce(r.servings, 1), 1) INTO base_servings
    FROM public.recipes r
    WHERE r.id = p_recipe_id
      AND (r.created_by = uid OR EXISTS (
        SELECT 1 FROM public.recipe_saves rs
        WHERE rs.recipe_id = r.id AND rs.user_id = uid
      ));
    IF NOT FOUND THEN RAISE EXCEPTION 'Rezept ist nicht verfügbar.'; END IF;
    target_servings := coalesce(p_servings, base_servings);
    IF target_servings < 1 OR target_servings > 12 THEN RAISE EXCEPTION 'Ungültige Personenzahl.'; END IF;
  ELSE
    IF coalesce(trim(p_decision_value), '') = '' THEN RAISE EXCEPTION 'Die Auswahl darf nicht leer sein.'; END IF;
    target_servings := 1;
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext(uid::text), hashtext(p_plan_date::text));

  SELECT id INTO pid
  FROM public.personal_today_plans
  WHERE user_id = uid AND plan_date = p_plan_date AND status = 'planned'
  ORDER BY created_at DESC LIMIT 1
  FOR UPDATE;

  IF pid IS NULL THEN
    RAISE EXCEPTION 'Für diesen Tag gibt es keine bestehende persönliche Entscheidung zum Ändern.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.shared_recipe_plans srp
    WHERE srp.plan_date = p_plan_date AND srp.status = 'planned'
      AND public.is_connection_member(srp.connection_id)
  ) THEN
    RAISE EXCEPTION 'An diesem Tag ist bereits ein gemeinsamer Essensplan eingetragen.';
  END IF;

  UPDATE public.personal_today_plans
  SET recipe_id = CASE WHEN normalized_type = 'recipe' THEN p_recipe_id ELSE NULL END,
      decision_type = normalized_type,
      decision_value = CASE WHEN normalized_type = 'recipe' THEN NULL ELSE trim(p_decision_value) END,
      servings = target_servings,
      updated_at = now()
  WHERE id = pid AND user_id = uid;

  DELETE FROM public.shopping_items
  WHERE personal_today_plan_id = pid AND source = 'recipe';

  IF normalized_type = 'recipe' THEN
    INSERT INTO public.shopping_items(personal_today_plan_id, food_id, name, quantity, unit, source)
    SELECT pid, ri.food_id, ri.name,
      round((ri.quantity * target_servings::numeric / greatest(base_servings, 1))::numeric, 2),
      ri.unit, 'recipe'
    FROM public.recipe_ingredients ri
    WHERE ri.recipe_id = p_recipe_id;
  END IF;

  RETURN pid;
END;
$function$;

REVOKE ALL ON FUNCTION public.replace_personal_plan_for_date(date, text, text, uuid, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.replace_personal_plan_for_date(date, text, text, uuid, integer) TO authenticated;
