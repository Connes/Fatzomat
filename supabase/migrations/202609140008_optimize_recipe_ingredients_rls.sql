drop policy if exists "recipe ingredients via own recipe" on public.recipe_ingredients;
create policy "recipe ingredients via own recipe" on public.recipe_ingredients
for all to authenticated
using (exists (select 1 from public.recipes r where r.id = recipe_id and r.created_by = (select auth.uid())))
with check (exists (select 1 from public.recipes r where r.id = recipe_id and r.created_by = (select auth.uid())));
