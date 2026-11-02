-- Complete the legacy onboarding catalog consolidation.
-- The previous migration did not move shopping_items.food_id before deleting
-- source foods. This migration handles the remaining duplicate seed IDs and
-- includes shopping-list references for any still-present legacy source.
-- User-created foods are never changed.

-- Free the unique display name before creating the canonical corn row.
update public.foods
set name = 'Legacy onboarding item ' || id
where id = 'onb_mais'
  and created_by is null
  and not exists (
    select 1 from public.foods canonical where canonical.id = 'corn'
  );

insert into public.foods (
  id, name, category, default_unit, aliases, search_terms, dietary_type, protein_type
)
select
  'corn', 'Mais', 'Gemüse', 'g', array[]::text[], array[]::text[], 'vegan', 'plant'
where not exists (select 1 from public.foods where id = 'corn');

-- Keep the legacy generic term searchable on the canonical mixed-mince entry.
update public.foods
set aliases = (
  select array_agg(distinct alias order by alias)
  from unnest(coalesce(aliases, array[]::text[]) || array['Hackfleisch']::text[]) as item(alias)
)
where id = 'mixed_minced_meat'
  and created_by is null;

create temporary table remaining_onboarding_food_merge_map (
  source_id text primary key,
  target_id text not null
) on commit drop;

insert into remaining_onboarding_food_merge_map (source_id, target_id)
values
  ('onb_hackfleisch', 'mixed_minced_meat'),
  ('onb_mais', 'corn');

do $$
begin
  if exists (
    select 1
    from remaining_onboarding_food_merge_map merge
    join public.foods source_food on source_food.id = merge.source_id
    left join public.foods target_food on target_food.id = merge.target_id
    where source_food.created_by is null
      and target_food.id is null
  ) then
    raise exception 'Food catalog consolidation aborted: canonical target missing';
  end if;
end;
$$;

insert into public.user_food_preferences (user_id, food_id, preference, created_at)
select preference.user_id, merge.target_id, preference.preference, preference.created_at
from public.user_food_preferences preference
join remaining_onboarding_food_merge_map merge on merge.source_id = preference.food_id
join public.foods source_food on source_food.id = merge.source_id
where source_food.created_by is null
on conflict (user_id, food_id) do nothing;

update public.recipe_ingredients ingredient
set food_id = merge.target_id
from remaining_onboarding_food_merge_map merge
join public.foods source_food on source_food.id = merge.source_id
where ingredient.food_id = merge.source_id
  and source_food.created_by is null;

-- Shopping items have an ON DELETE SET NULL FK, so move them before deleting
-- the source food or their structured food reference would be lost.
update public.shopping_items item
set food_id = merge.target_id
from remaining_onboarding_food_merge_map merge
join public.foods source_food on source_food.id = merge.source_id
where item.food_id = merge.source_id
  and source_food.created_by is null;

delete from public.foods source_food
using remaining_onboarding_food_merge_map merge
where source_food.id = merge.source_id
  and source_food.created_by is null;
