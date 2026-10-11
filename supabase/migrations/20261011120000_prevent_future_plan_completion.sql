-- Defense in depth: future plans may never enter the completed/cooked state,
-- even if a new client path or a direct table write bypasses the current UI/RPC.
CREATE OR REPLACE FUNCTION public.prevent_future_personal_plan_completion()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF NEW.status = 'cooked' AND NEW.plan_date > current_date THEN
    RAISE EXCEPTION 'Zukünftige Entscheidungen können nicht als abgeschlossen markiert werden.'
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS prevent_future_personal_plan_completion
  ON public.personal_today_plans;

CREATE TRIGGER prevent_future_personal_plan_completion
BEFORE INSERT OR UPDATE OF status, plan_date
ON public.personal_today_plans
FOR EACH ROW
EXECUTE FUNCTION public.prevent_future_personal_plan_completion();
