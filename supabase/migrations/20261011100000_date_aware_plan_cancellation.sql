-- Cancel the exact personal plan selected by the user, regardless of its date.
-- The previous implementation constrained the update to current_date and could
-- delete shopping rows before discovering that a future plan could not be cancelled.
CREATE OR REPLACE FUNCTION public.cancel_personal_today_plan(p_plan_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  uid uuid := auth.uid();
  changed_id uuid;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Keine Supabase-Sitzung vorhanden.';
  END IF;

  UPDATE public.personal_today_plans
  SET status = 'cancelled',
      updated_at = now()
  WHERE id = p_plan_id
    AND user_id = uid
    AND status = 'planned'
  RETURNING id INTO changed_id;

  IF changed_id IS NULL THEN
    RETURN false;
  END IF;

  DELETE FROM public.shopping_items
  WHERE personal_today_plan_id = changed_id;

  RETURN true;
END;
$function$;

REVOKE ALL ON FUNCTION public.cancel_personal_today_plan(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.cancel_personal_today_plan(uuid) TO authenticated;
