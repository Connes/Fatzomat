-- Expand the standard onboarding catalog with additional meat, fish and vegetable options.
-- ON CONFLICT DO NOTHING keeps this safe to re-run against databases with partially seeded catalogs.
insert into public.foods (id, name, category, default_unit) values
  ('beef_tenderloin', 'Rinderfilet', 'Fleisch', 'g'),
  ('beef_roast', 'Rinderbraten', 'Fleisch', 'g'),
  ('mixed_minced_meat', 'Gemischtes Hackfleisch', 'Fleisch', 'g'),
  ('lamb_chops', 'Lammkotelett', 'Fleisch', 'g'),
  ('lamb_minced_meat', 'Lammhackfleisch', 'Fleisch', 'g'),
  ('duck_breast', 'Entenbrust', 'Fleisch', 'g'),
  ('chicken_wings', 'Hähnchenflügel', 'Fleisch', 'Stück'),
  ('chicken_minced_meat', 'Hähnchenhackfleisch', 'Fleisch', 'g'),
  ('pork_roast', 'Schweinebraten', 'Fleisch', 'g'),
  ('pork_ribs', 'Spareribs', 'Fleisch', 'g'),
  ('beef_rouladen', 'Rinderrouladen', 'Fleisch', 'g'),
  ('veal', 'Kalbfleisch', 'Fleisch', 'g'),
  ('pork_minced_meat', 'Schweinehackfleisch', 'Fleisch', 'g'),
  ('chicken_inner_fillet', 'Hähncheninnenfilet', 'Fleisch', 'g'),
  ('kassler', 'Kassler', 'Fleisch', 'g'),
  ('mackerel', 'Makrele', 'Fisch', 'g'),
  ('herring', 'Hering', 'Fisch', 'g'),
  ('halibut', 'Heilbutt', 'Fisch', 'g'),
  ('redfish', 'Rotbarsch', 'Fisch', 'g'),
  ('sea_bream', 'Dorade', 'Fisch', 'g'),
  ('sea_bass', 'Wolfsbarsch', 'Fisch', 'g'),
  ('pangasius', 'Pangasius', 'Fisch', 'g'),
  ('squid', 'Tintenfisch', 'Meeresfrüchte', 'g'),
  ('mussels', 'Miesmuscheln', 'Meeresfrüchte', 'g'),
  ('smoked_salmon', 'Räucherlachs', 'Fisch', 'g'),
  ('anchovies', 'Sardellen', 'Fisch', 'g'),
  ('crab_meat', 'Krabben', 'Meeresfrüchte', 'g'),
  ('fennel', 'Fenchel', 'Gemüse', 'Stück'),
  ('radish', 'Radieschen', 'Gemüse', 'g'),
  ('beetroot', 'Rote Bete', 'Gemüse', 'g'),
  ('parsnip', 'Pastinake', 'Gemüse', 'g'),
  ('parsley_root', 'Petersilienwurzel', 'Gemüse', 'g'),
  ('pak_choi', 'Pak Choi', 'Gemüse', 'g'),
  ('chinese_cabbage', 'Chinakohl', 'Gemüse', 'g'),
  ('white_cabbage', 'Weißkohl', 'Gemüse', 'g'),
  ('pointed_cabbage', 'Spitzkohl', 'Gemüse', 'g'),
  ('chard', 'Mangold', 'Gemüse', 'g'),
  ('endive', 'Endivie', 'Gemüse', 'g'),
  ('chicory', 'Chicorée', 'Gemüse', 'g'),
  ('artichoke', 'Artischocke', 'Gemüse', 'Stück'),
  ('okra', 'Okra', 'Gemüse', 'g'),
  ('sweet_potato', 'Süßkartoffel', 'Gemüse', 'g'),
  ('kohlrabi', 'Kohlrabi', 'Gemüse', 'Stück'),
  ('radish_root', 'Rettich', 'Gemüse', 'Stück'),
  ('spring_onion', 'Frühlingszwiebel', 'Gemüse', 'Bund'),
  ('shallot', 'Schalotte', 'Gemüse', 'Stück'),
  ('sugar_snap_peas', 'Zuckerschoten', 'Gemüse', 'g'),
  ('romanesco', 'Romanesco', 'Gemüse', 'g'),
  ('cherry_tomatoes', 'Cherrytomaten', 'Gemüse', 'g'),
  ('red_chili_pepper', 'Frische Chilischote', 'Gemüse', 'Stück'),
  ('watercress', 'Brunnenkresse', 'Gemüse', 'g'),
  ('corn_salad', 'Feldsalat', 'Gemüse', 'g'),
  ('celeriac', 'Knollensellerie', 'Gemüse', 'Stück'),
  ('celery_stalk', 'Stangensellerie', 'Gemüse', 'g'),
  ('rutabaga', 'Steckrübe', 'Gemüse', 'g'),
  ('shiitake_mushrooms', 'Shiitake-Pilze', 'Gemüse', 'g'),
  ('oyster_mushrooms', 'Austernpilze', 'Gemüse', 'g')
on conflict do nothing;

-- Add common fresh and dried herbs to the shared onboarding catalog.
insert into public.foods (id, name, category, default_unit) values
  ('dill', 'Dill', 'Gewürze & Kräuter', 'g'),
  ('chives', 'Schnittlauch', 'Gewürze & Kräuter', 'g'),
  ('coriander_leaves', 'Koriander', 'Gewürze & Kräuter', 'g'),
  ('mint', 'Minze', 'Gewürze & Kräuter', 'g'),
  ('sage', 'Salbei', 'Gewürze & Kräuter', 'g'),
  ('marjoram', 'Majoran', 'Gewürze & Kräuter', 'g'),
  ('tarragon', 'Estragon', 'Gewürze & Kräuter', 'g'),
  ('lovage', 'Liebstöckel', 'Gewürze & Kräuter', 'g'),
  ('lemon_balm', 'Zitronenmelisse', 'Gewürze & Kräuter', 'g'),
  ('lemongrass', 'Zitronengras', 'Gewürze & Kräuter', 'Stück'),
  ('bay_leaf', 'Lorbeerblatt', 'Gewürze & Kräuter', 'Stück'),
  ('cloves', 'Nelken', 'Gewürze & Kräuter', 'g'),
  ('cardamom', 'Kardamom', 'Gewürze & Kräuter', 'g'),
  ('coriander_seeds', 'Koriandersamen', 'Gewürze & Kräuter', 'g'),
  ('fennel_seeds', 'Fenchelsamen', 'Gewürze & Kräuter', 'g'),
  ('mustard_seeds', 'Senfkörner', 'Gewürze & Kräuter', 'g'),
  ('garam_masala', 'Garam Masala', 'Gewürze & Kräuter', 'g'),
  ('italian_herbs', 'Italienische Kräuter', 'Gewürze & Kräuter', 'g'),
  ('herbes_de_provence', 'Kräuter der Provence', 'Gewürze & Kräuter', 'g'),
  ('smoked_paprika', 'Geräuchertes Paprikapulver', 'Gewürze & Kräuter', 'g')
on conflict do nothing;

-- Normalize category names for existing catalog items and user-created foods.
update public.foods
set category = 'Gewürze & Kräuter'
where category = 'Gewürze';

update public.foods
set category = 'Milchprodukte & Eier'
where category = 'Milchprodukte';

-- Keep the egg in the combined dairy-and-eggs category even if it was seeded
-- under a different category in an older database.
update public.foods
set category = 'Milchprodukte & Eier'
where id = 'egg';

-- Sonstiges remains the intentional catch-all category for uncategorized foods.
