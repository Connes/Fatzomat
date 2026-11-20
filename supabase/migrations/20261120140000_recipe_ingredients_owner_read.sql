-- Owners must be able to read the ingredients belonging to their own recipes.
-- The previous collection-hardening migration removed broad reads but did not
-- replace them with this owner-scoped SELECT policy.
drop policy if exists "recipe ingredients owner read" on public.recipe_ingredients;
create policy "recipe ingredients owner read"
on public.recipe_ingredients
for select
to authenticated
using (
  exists (
    select 1
    from public.recipes r
    where r.id = recipe_ingredients.recipe_id
      and r.created_by = (select auth.uid())
  )
);
