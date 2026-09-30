-- V54: editable shopping list. Manual items never modify the source recipe.
alter table public.shopping_items
  add column if not exists source text not null default 'recipe';

alter table public.shopping_items
  drop constraint if exists shopping_items_source_check;
alter table public.shopping_items
  add constraint shopping_items_source_check check (source in ('recipe','manual'));

create index if not exists idx_shopping_items_plan_source
  on public.shopping_items(shared_recipe_plan_id, source);
