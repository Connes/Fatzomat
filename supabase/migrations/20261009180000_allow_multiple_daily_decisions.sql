-- Allow a user to complete one meal and make a separate decision later the same day.
-- Only one *open* plan is allowed per user/day; cooked entries remain as history.
DROP INDEX IF EXISTS public.personal_today_plans_one_active_per_user_day;
CREATE UNIQUE INDEX personal_today_plans_one_open_per_user_day
  ON public.personal_today_plans (user_id, plan_date)
  WHERE status = 'planned';

CREATE OR REPLACE FUNCTION public.set_personal_today_plan(
  p_recipe_id uuid,
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
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'Keine Supabase-Sitzung vorhanden.'; END IF;
  SELECT servings INTO base_servings FROM public.recipes WHERE id = p_recipe_id;
  IF base_servings IS NULL THEN RAISE EXCEPTION 'Rezept ist nicht verfügbar.'; END IF;
  target_servings := coalesce(p_servings, base_servings);
  IF target_servings < 1 OR target_servings > 12 THEN RAISE EXCEPTION 'Ungültige Personenzahl.'; END IF;

  SELECT id INTO pid
  FROM public.personal_today_plans
  WHERE user_id = uid AND plan_date = current_date AND status = 'planned'
  ORDER BY created_at DESC
  LIMIT 1;

  IF pid IS NULL THEN
    INSERT INTO public.personal_today_plans(user_id, recipe_id, plan_date, status, servings)
    VALUES(uid, p_recipe_id, current_date, 'planned', target_servings)
    RETURNING id INTO pid;
  ELSE
    UPDATE public.personal_today_plans
      SET recipe_id = p_recipe_id, decision_type = 'recipe', decision_value = NULL,
          status = 'planned', servings = target_servings, updated_at = now()
      WHERE id = pid AND user_id = uid;
  END IF;

  DELETE FROM public.shopping_items WHERE personal_today_plan_id = pid AND source = 'recipe';
  INSERT INTO public.shopping_items(personal_today_plan_id, food_id, name, quantity, unit, source)
  SELECT pid, ri.food_id, ri.name,
    round((ri.quantity * target_servings::numeric / greatest(base_servings, 1))::numeric, 2),
    ri.unit, 'recipe'
  FROM public.recipe_ingredients ri WHERE ri.recipe_id = p_recipe_id;
  RETURN pid;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_personal_today_decision(
  p_decision_type text,
  p_decision_value text
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  uid uuid := auth.uid();
  pid uuid;
  normalized_type text := lower(trim(p_decision_type));
  normalized_value text := trim(p_decision_value);
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'Keine Supabase-Sitzung vorhanden.'; END IF;
  IF normalized_type NOT IN ('order', 'dine_out', 'surprise') THEN
    RAISE EXCEPTION 'Ungültiger persönlicher Entscheidungstyp.';
  END IF;
  IF normalized_value = '' THEN RAISE EXCEPTION 'Die Auswahl darf nicht leer sein.'; END IF;

  SELECT id INTO pid FROM public.personal_today_plans
  WHERE user_id = uid AND plan_date = current_date AND status = 'planned'
  ORDER BY created_at DESC LIMIT 1;

  IF pid IS NULL THEN
    INSERT INTO public.personal_today_plans(
      user_id, recipe_id, decision_type, decision_value, plan_date, status, servings
    ) VALUES(uid, NULL, normalized_type, normalized_value, current_date, 'planned', 1)
    RETURNING id INTO pid;
  ELSE
    DELETE FROM public.shopping_items WHERE personal_today_plan_id = pid;
    UPDATE public.personal_today_plans
      SET recipe_id = NULL, decision_type = normalized_type,
          decision_value = normalized_value, status = 'planned',
          servings = 1, updated_at = now()
      WHERE id = pid AND user_id = uid;
  END IF;

  INSERT INTO public.personal_decision_history(user_id, plan_id, recipe_id, action, source)
  VALUES(uid, pid, NULL, 'selected', 'today');
  RETURN pid;
END;
$function$;
