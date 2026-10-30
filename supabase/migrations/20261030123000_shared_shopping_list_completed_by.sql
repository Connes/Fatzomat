-- Persist who marked a shared shopping list complete.
ALTER TABLE public.shared_recipe_plans
  ADD COLUMN IF NOT EXISTS shopping_list_completed_by uuid
  REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE OR REPLACE FUNCTION public.complete_shared_shopping_list(p_plan_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  cid uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Keine Supabase-Sitzung vorhanden.';
  END IF;

  SELECT connection_id INTO cid
  FROM public.shared_recipe_plans
  WHERE id = p_plan_id
    AND plan_date >= current_date
    AND status <> 'cancelled';

  IF cid IS NULL OR NOT public.is_connection_member(cid) THEN
    RAISE EXCEPTION 'Gemeinsame Einkaufsliste ist nicht verfügbar.';
  END IF;

  UPDATE public.shared_recipe_plans
  SET shopping_list_completed_at = COALESCE(shopping_list_completed_at, now()),
      shopping_list_completed_by = COALESCE(shopping_list_completed_by, auth.uid())
  WHERE id = p_plan_id;

  RETURN true;
END;
$function$;

REVOKE ALL ON FUNCTION public.complete_shared_shopping_list(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_shared_shopping_list(uuid) TO authenticated;
