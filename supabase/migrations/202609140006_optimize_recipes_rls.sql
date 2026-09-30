drop policy if exists "own recipes" on public.recipes;
create policy "own recipes" on public.recipes
for all to authenticated
using (created_by = (select auth.uid()))
with check (created_by = (select auth.uid()));
