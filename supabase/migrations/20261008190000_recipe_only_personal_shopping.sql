-- A personal shopping list is meaningful only for a recipe selected for today.
-- Ordering, dining out and surprise decisions must never accept shopping items.

drop policy if exists "shopping personal insert" on public.shopping_items;

create policy "shopping personal insert" on public.shopping_items
for insert to authenticated
with check (
  (
    personal_today_plan_id is not null
    and shared_recipe_plan_id is null
    and exists (
      select 1
      from public.personal_today_plans p
      where p.id = shopping_items.personal_today_plan_id
        and p.user_id = (select auth.uid())
        and p.decision_type = 'recipe'
        and p.recipe_id is not null
    )
  )
  or (
    personal_today_plan_id is null
    and shared_recipe_plan_id is not null
    and exists (
      select 1
      from public.shared_recipe_plans sp
      where sp.id = shopping_items.shared_recipe_plan_id
        and public.is_connection_member(sp.connection_id)
    )
  )
);
