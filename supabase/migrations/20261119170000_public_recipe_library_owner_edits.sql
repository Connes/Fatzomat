-- Every authenticated app user can discover and read every recipe.
-- Ownership remains exclusive: the existing "own recipes" ALL policy and
-- owner checks in update/delete operations continue to protect mutations.

 drop policy if exists "recipes global library read" on public.recipes;
 create policy "recipes global library read"
   on public.recipes for select to authenticated using (true);

 drop policy if exists "recipe ingredients global library read" on public.recipe_ingredients;
 create policy "recipe ingredients global library read"
   on public.recipe_ingredients for select to authenticated using (true);
