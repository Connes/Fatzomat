-- Consolidate legacy onboarding seed IDs into the canonical shared food catalog.
-- Preserve user preferences and recipe references before removing legacy rows.
-- User-created foods are never touched.

-- Free unique names that must move to a new canonical ID.
update public.foods
set name = 'Legacy onboarding item ' || id
where created_by is null
  and id in (
    'onb_schweinefleisch', 'onb_salami', 'onb_speck',
    'onb_mango', 'onb_pfirsich', 'onb_bohnen'
  )
  and not exists (
    select 1
    from public.foods canonical
    where canonical.id = case public.foods.id
      when 'onb_schweinefleisch' then 'pork_chop'
      when 'onb_salami' then 'salami'
      when 'onb_speck' then 'bacon'
      when 'onb_mango' then 'mango'
      when 'onb_pfirsich' then 'peach'
      when 'onb_bohnen' then 'green_beans'
    end
  );

-- Ensure every target exists before references are moved. Existing canonical
-- rows win; legacy rows are only renamed above when their name would conflict.
insert into public.foods (id, name, category, default_unit, aliases)
values
  ('pork_chop', 'Schweinefleisch', 'Fleisch', 'g',
    array['Schweinekotelett', 'Schweinefilet', 'Schweinebraten', 'Spareribs', 'Schweinehackfleisch', 'Kassler']),
  ('turkey_breast', 'Putenfleisch', 'Fleisch', 'g', array['Putenbrust']),
  ('salami', 'Salami', 'Fleisch', 'g', array[]::text[]),
  ('bacon', 'Speck', 'Fleisch', 'g', array[]::text[]),
  ('sausage', 'Wurst', 'Fleisch', 'g', array['Würstchen', 'Bratwurst']),
  ('shrimp', 'Garnele', 'Meeresfrüchte', 'g', array['Garnelen']),
  ('mushrooms', 'Pilz', 'Gemüse', 'g', array['Champignon', 'Champignons', 'Shiitake-Pilze', 'Austernpilze']),
  ('green_beans', 'Grüne Bohnen', 'Gemüse', 'g', array['Bohnen']),
  ('mango', 'Mango', 'Obst', 'Stück', array[]::text[]),
  ('peach', 'Pfirsich', 'Obst', 'Stück', array[]::text[]),
  ('yogurt', 'Joghurt', 'Milchprodukte & Eier', 'g', array['Naturjoghurt', 'Griechischer Joghurt'])
on conflict (id) do nothing;

create temporary table onboarding_food_merge_map (
  source_id text primary key,
  target_id text not null
) on commit drop;

insert into onboarding_food_merge_map (source_id, target_id) values
  ('onb_hähnchen', 'chicken_breast'),
  ('onb_beef_steak', 'ground_beef'),
  ('onb_schweinefleisch', 'pork_chop'),
  ('onb_putenbrust', 'turkey_breast'),
  ('onb_salami', 'salami'),
  ('onb_speck', 'bacon'),
  ('onb_wuerstchen', 'sausage'),
  ('onb_garnelen', 'shrimp'),
  ('onb_champignons', 'mushrooms'),
  ('onb_erbsen', 'peas'),
  ('onb_bohnen', 'green_beans'),
  ('onb_mango', 'mango'),
  ('onb_pfirsich', 'peach'),
  ('onb_griechischer_joghurt', 'yogurt'),
  ('onb_joghurt', 'yogurt');

-- Fail atomically rather than deleting a source if a canonical target could
-- not be created because a database constraint or an unexpected seed blocked it.
do $$
begin
  if exists (
    select 1
    from onboarding_food_merge_map merge
    left join public.foods target on target.id = merge.target_id
    where target.id is null
  ) then
    raise exception 'Food catalog consolidation aborted: canonical target missing';
  end if;
end;
$$;

insert into public.user_food_preferences (user_id, food_id, preference, created_at)
select preference.user_id, merge.target_id, preference.preference, preference.created_at
from public.user_food_preferences preference
join onboarding_food_merge_map merge on merge.source_id = preference.food_id
join public.foods source_food on source_food.id = merge.source_id
where source_food.created_by is null
on conflict (user_id, food_id) do nothing;

update public.recipe_ingredients ingredient
set food_id = merge.target_id
from onboarding_food_merge_map merge
join public.foods source_food on source_food.id = merge.source_id
where ingredient.food_id = merge.source_id
  and source_food.created_by is null;

delete from public.foods source_food
using onboarding_food_merge_map merge
where source_food.id = merge.source_id
  and source_food.created_by is null;

-- Garnelen belong to seafood, including the already-canonical row on installs
-- where it was seeded independently of the onboarding ID.
update public.foods
set category = 'Meeresfrüchte'
where id = 'shrimp'
  and created_by is null;
