-- Allow a connected partner to read ingredients for recipes used in an active shared plan.
-- The existing owner-only recipe_ingredients policy remains in place for writes.
drop policy if exists "shared recipe ingredients readable by connection" on public.recipe_ingredients;
create policy "shared recipe ingredients readable by connection"
on public.recipe_ingredients for select to authenticated
using (
  exists (
    select 1
    from public.shared_recipe_plans sp
    where sp.recipe_id = recipe_ingredients.recipe_id
      and sp.status <> 'cancelled'
      and public.is_connection_member(sp.connection_id)
  )
);
