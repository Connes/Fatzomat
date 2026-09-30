-- Keep personal Today writes SECURITY INVOKER while removing the recursive RLS
-- dependency introduced by resolved-decision recipe read policies.
--
-- The recipes policy used to inspect personal_today_plans directly. The
-- personal_today_plans INSERT/UPDATE policy, in turn, validates recipe access
-- by querying recipes. During set_personal_today_plan this creates a circular
-- RLS evaluation path. A private SECURITY DEFINER helper isolates the one
-- cross-table existence check without exposing a general-purpose RPC.
create schema if not exists private;

create or replace function private.has_personal_recipe_reference(p_recipe_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    auth.uid() is not null
    and (
      exists (
        select 1
        from public.personal_today_plans p
        where p.user_id = auth.uid()
          and p.recipe_id = p_recipe_id
      )
      or exists (
        select 1
        from public.personal_decision_history h
        where h.user_id = auth.uid()
          and h.recipe_id = p_recipe_id
      )
    );
$$;

revoke all on function private.has_personal_recipe_reference(uuid) from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.has_personal_recipe_reference(uuid) to authenticated;

-- The resolved-decision read path now uses the isolated helper instead of
-- directly re-entering personal_today_plans during recipe RLS evaluation.
drop policy if exists "recipes resolved decision read" on public.recipes;
create policy "recipes resolved decision read"
on public.recipes for select to authenticated
using (private.has_personal_recipe_reference(recipes.id));

drop policy if exists "recipe ingredients resolved decision read" on public.recipe_ingredients;
create policy "recipe ingredients resolved decision read"
on public.recipe_ingredients for select to authenticated
using (private.has_personal_recipe_reference(recipe_ingredients.recipe_id));

-- Restore the intended Personal-First architecture: table RLS remains the
-- authorization boundary for the personal Today RPC.
alter function public.set_personal_today_plan(uuid, integer) security invoker;
