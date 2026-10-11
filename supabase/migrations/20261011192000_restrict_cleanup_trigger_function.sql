-- The cleanup routine is invoked by a database trigger only, not by API callers.
REVOKE ALL ON FUNCTION public.cleanup_personal_plan_shopping_items()
  FROM PUBLIC, anon, authenticated;
