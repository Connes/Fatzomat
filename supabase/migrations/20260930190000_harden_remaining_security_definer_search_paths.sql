-- Harden SECURITY DEFINER functions that were introduced or recreated after the
-- initial search_path hardening migration.
-- All referenced functions use schema-qualified public objects only.

alter function public.create_recipe_suggestion(uuid)
  set search_path = public;
alter function public.respond_to_recipe_suggestion(uuid, boolean)
  set search_path = public;
alter function public.push_notifications_webhook()
  set search_path = public;
alter function public.cancel_personal_today_plan(uuid)
  set search_path = public;
alter function public.send_decision_message(text, text, text, integer)
  set search_path = public;
alter function public.set_personal_today_plan(uuid, integer)
  set search_path = public;
alter function public.update_shared_recipe(uuid, jsonb, jsonb)
  set search_path = public;
alter function public.remove_shared_recipe(uuid)
  set search_path = public;
alter function public.find_shared_recipe_duplicate(jsonb, jsonb)
  set search_path = public;
alter function public.create_shared_recipe(jsonb, jsonb, boolean)
  set search_path = public;
alter function public.remove_recipe_from_collection(uuid)
  set search_path = public;
alter function public.accept_decision_share(uuid)
  set search_path = public;
