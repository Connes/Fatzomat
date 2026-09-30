-- Technical hardening: SECURITY DEFINER functions must not include pg_temp
-- in search_path when they do not require temporary objects.
-- All affected functions use schema-qualified public objects only.

alter function public.create_connection()
  set search_path = public;

alter function public.create_decision_request(uuid)
  set search_path = public;

alter function public.accept_decision_request(uuid)
  set search_path = public;

alter function public.resolve_decision_request(uuid, text, text, text, integer)
  set search_path = public;

alter function public.cancel_decision_request(uuid)
  set search_path = public;

alter function public.update_shared_recipe_plan_servings(uuid, integer)
  set search_path = public;

alter function public.cancel_shared_recipe_plan(uuid)
  set search_path = public;

alter function public.replace_shared_recipe_plan(uuid, uuid, integer)
  set search_path = public;

alter function public.share_recipe_for_today(uuid, integer)
  set search_path = public;

alter function public.add_favorite_recipe(text, text, jsonb, jsonb)
  set search_path = public;

alter function public.create_recipe_suggestion(uuid)
  set search_path = public;

alter function public.save_recipe_with_ingredients(jsonb, jsonb)
  set search_path = public;

alter function public.respond_to_recipe_suggestion(uuid, boolean)
  set search_path = public;
