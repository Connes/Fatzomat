-- The RPC validates auth.uid(), plan ownership, date, and allowed status itself.
-- Run it with the function owner's privileges so RLS policies for recipe selection
-- do not block status-only updates for recipes from the global library.
ALTER FUNCTION public.update_personal_today_status(uuid, text)
  SECURITY DEFINER;

ALTER FUNCTION public.update_personal_today_status(uuid, text)
  SET search_path = public, pg_temp;

REVOKE ALL ON FUNCTION public.update_personal_today_status(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_personal_today_status(uuid, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.update_personal_today_status(uuid, text) TO authenticated;
