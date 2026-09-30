-- Personal Today RPCs run with caller privileges so RLS remains the authorization boundary.
alter function public.set_personal_today_plan(uuid,integer) security invoker;
alter function public.update_personal_today_plan_servings(uuid,integer) security invoker;
alter function public.cancel_personal_today_plan(uuid) security invoker;
alter function public.update_personal_today_status(uuid,text) security invoker;
