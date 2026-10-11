-- Keep personal shopping items strictly tied to an active decision.
-- The application RPC already deletes these rows on cancellation; this trigger
-- makes the invariant hold for every cancellation/write path, including future dates.
CREATE OR REPLACE FUNCTION public.cleanup_personal_plan_shopping_items()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    DELETE FROM public.shopping_items
    WHERE personal_today_plan_id = OLD.id;
    RETURN OLD;
  END IF;

  IF OLD.status IS DISTINCT FROM NEW.status
     AND NEW.status = 'cancelled' THEN
    DELETE FROM public.shopping_items
    WHERE personal_today_plan_id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS cleanup_personal_plan_shopping_items
  ON public.personal_today_plans;

CREATE TRIGGER cleanup_personal_plan_shopping_items
AFTER UPDATE OF status OR DELETE
ON public.personal_today_plans
FOR EACH ROW
EXECUTE FUNCTION public.cleanup_personal_plan_shopping_items();

-- This function is trigger-only and must not be callable through PostgREST RPC.
REVOKE ALL ON FUNCTION public.cleanup_personal_plan_shopping_items()
  FROM PUBLIC, anon, authenticated;

-- Remove shopping rows left behind by earlier cancellation paths.
DELETE FROM public.shopping_items AS item
USING public.personal_today_plans AS plan
WHERE item.personal_today_plan_id = plan.id
  AND plan.status = 'cancelled';
