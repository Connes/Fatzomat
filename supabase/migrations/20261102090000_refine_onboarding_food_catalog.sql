-- Refine the shared onboarding catalog while preserving references from preferences and recipes.
-- Only standard catalog rows are changed; user-created foods remain untouched.

create temporary table food_catalog_merge_map (
  source_id text primary key,
  target_id text not null
) on commit drop;

insert into food_catalog_merge_map (source_id, target_id) values
  ('chicken_thigh', 'chicken_breast'),
  ('chicken_wings', 'chicken_breast'),
  ('chicken_minced_meat', 'chicken_breast'),
  ('chicken_inner_fillet', 'chicken_breast'),
  ('beef_steak', 'ground_beef'),
  ('beef_tenderloin', 'ground_beef'),
  ('beef_roast', 'ground_beef'),
  ('beef_rouladen', 'ground_beef'),
  ('pork_tenderloin', 'pork_chop'),
  ('pork_roast', 'pork_chop'),
  ('pork_ribs', 'pork_chop'),
  ('pork_minced_meat', 'pork_chop'),
  ('kassler', 'pork_chop'),
  ('lamb_minced_meat', 'lamb_chops'),
  ('bratwurst', 'sausage'),
  ('greek_yogurt', 'yogurt'),
  ('shiitake_mushrooms', 'mushrooms'),
  ('oyster_mushrooms', 'mushrooms');

-- Move saved preferences first. If a user already rated the canonical item,
-- keep that existing preference rather than silently overwriting it.
insert into public.user_food_preferences (user_id, food_id, preference, created_at)
select preference.user_id, merge.target_id, preference.preference, preference.created_at
from public.user_food_preferences as preference
join food_catalog_merge_map as merge on merge.source_id = preference.food_id
join public.foods as source_food on source_food.id = merge.source_id
where source_food.created_by is null
on conflict (user_id, food_id) do nothing;

-- Keep recipe ingredient links attached to the canonical food. The ingredient
-- display name and quantity remain unchanged for existing recipes.
update public.recipe_ingredients as ingredient
set food_id = merge.target_id
from food_catalog_merge_map as merge
join public.foods as source_food on source_food.id = merge.source_id
where ingredient.food_id = merge.source_id
  and source_food.created_by is null;

delete from public.foods as source_food
using food_catalog_merge_map as merge
where source_food.id = merge.source_id
  and source_food.created_by is null;

-- Consolidated meat labels. Existing stable IDs are retained for the canonical rows.
update public.foods set name = 'Hähnchenfleisch',
  aliases = array['Hähnchenbrust', 'Hähnchenschenkel', 'Hähnchenflügel', 'Hähnchenhackfleisch', 'Hähncheninnenfilet']
where id = 'chicken_breast' and created_by is null;

update public.foods set name = 'Rindfleisch',
  aliases = array['Rinderhackfleisch', 'Rindersteak', 'Rinderfilet', 'Rinderbraten', 'Rinderrouladen']
where id = 'ground_beef' and created_by is null;

update public.foods set name = 'Schweinefleisch',
  aliases = array['Schweinekotelett', 'Schweinefilet', 'Schweinebraten', 'Spareribs', 'Schweinehackfleisch', 'Kassler']
where id = 'pork_chop' and created_by is null;

update public.foods set name = 'Lammfleisch',
  aliases = array['Lammkotelett', 'Lammhackfleisch']
where id = 'lamb_chops' and created_by is null;

update public.foods set name = 'Putenfleisch',
  aliases = array['Putenbrust']
where id = 'turkey_breast' and created_by is null;

update public.foods set name = 'Ente',
  aliases = array['Entenbrust']
where id = 'duck_breast' and created_by is null;

update public.foods set name = 'Kalbfleisch'
where id = 'veal' and created_by is null;

update public.foods set name = 'Speck'
where id = 'bacon' and created_by is null;

update public.foods set name = 'Salami'
where id = 'salami' and created_by is null;

update public.foods set name = 'Wurst',
  aliases = array['Würstchen', 'Bratwurst']
where id = 'sausage' and created_by is null;

update public.foods set name = 'Joghurt', aliases = array['Naturjoghurt', 'Griechischer Joghurt']
where id = 'yogurt' and created_by is null;

update public.foods set name = 'Gemischtes Hackfleisch',
  aliases = array['Gemischtes Hack', 'Hackfleisch gemischt']
where id = 'mixed_minced_meat' and created_by is null;

-- Garnelen are seafood, not fish.
update public.foods set category = 'Meeresfrüchte'
where id = 'shrimp' and created_by is null;

-- Consolidated mushroom entry and remaining vegetable naming.
update public.foods set name = 'Pilz',
  aliases = array['Champignons', 'Shiitake-Pilze', 'Austernpilze']
where id = 'mushrooms' and created_by is null;

update public.foods set name = 'Kresse',
  aliases = array['Brunnenkresse']
where id = 'watercress' and created_by is null;

-- Keep the fresh chili entry, but simplify its display name as requested.
update public.foods set name = 'Chilischote',
  aliases = array['Frische Chilischote']
where id = 'red_chili_pepper' and created_by is null;

delete from public.foods
where created_by is null
  and id in (
    'cherry_tomatoes', 'red_onion', 'celeriac', 'celery_stalk',
    'pointed_cabbage', 'lettuce', 'parsley_root', 'okra', 'ham',
    'italian_herbs', 'herbes_de_provence', 'garam_masala'
  );

-- Canonical category names and the agreed final category set.
update public.foods
set category = case
  when category = 'Milchprodukte' then 'Milchprodukte & Eier'
  when category = 'Gewürze' then 'Gewürze & Kräuter'
  when id = 'tofu' then 'Getreide & Beilagen'
  when id = 'coconut_milk' then 'Saucen & Grundzutaten'
  when id = 'sesame' then 'Nüsse & Kerne'
  else category
end
where created_by is null
  and (
    category in ('Milchprodukte', 'Gewürze', 'Sonstiges', 'Pflanzliche Alternativen')
    or id in ('tofu', 'coconut_milk', 'sesame')
  );

-- Restore commonly used catalog items that were missing from older seed data,
-- and add the agreed practical additions.
insert into public.foods (id, name, category, default_unit, search_terms, dietary_type, protein_type)
values
  ('mango', 'Mango', 'Obst', 'Stück', array[]::text[], 'vegan', 'plant'),
  ('peach', 'Pfirsich', 'Obst', 'Stück', array[]::text[], 'vegan', 'plant'),
  ('green_beans', 'Grüne Bohnen', 'Gemüse', 'g', array[]::text[], 'vegan', 'plant'),
  ('peas', 'Erbsen', 'Gemüse', 'g', array[]::text[], 'vegan', 'plant'),
  ('corn', 'Mais', 'Gemüse', 'g', array[]::text[], 'vegan', 'plant'),
  ('tofu', 'Tofu', 'Getreide & Beilagen', 'g', array['Sojatofu']::text[], 'vegan', 'plant'),
  ('sour_cream', 'Schmand', 'Milchprodukte & Eier', 'g', array[]::text[], 'vegetarian', 'dairy'),
  ('skyr', 'Skyr', 'Milchprodukte & Eier', 'g', array[]::text[], 'vegetarian', 'dairy')
on conflict (id) do update
set name = excluded.name,
    category = excluded.category,
    default_unit = excluded.default_unit,
    dietary_type = excluded.dietary_type,
    protein_type = excluded.protein_type
where public.foods.created_by is null;
