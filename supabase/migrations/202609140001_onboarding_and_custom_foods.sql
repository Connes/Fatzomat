alter table public.profiles
  add column if not exists onboarding_completed boolean not null default false;

alter table public.foods
  add column if not exists created_by uuid references auth.users(id) on delete cascade;

drop policy if exists "foods readable by authenticated" on public.foods;
create policy "foods readable by authenticated"
on public.foods for select to authenticated
using (created_by is null or created_by = auth.uid());

create policy "foods own insert"
on public.foods for insert to authenticated
with check (created_by = auth.uid());

create index if not exists idx_foods_created_by on public.foods(created_by);

insert into public.foods (id,name,category,default_unit) values
('beef_steak','Rindersteak','Fleisch','g'),('pork_chop','Schweinekotelett','Fleisch','g'),('pork_tenderloin','Schweinefilet','Fleisch','g'),
('bacon','Speck','Fleisch','g'),('ham','Schinken','Fleisch','g'),('salami','Salami','Fleisch','g'),('sausage','Würstchen','Fleisch','Stück'),
('bratwurst','Bratwurst','Fleisch','Stück'),('turkey_breast','Putenbrust','Fleisch','g'),('chicken_thigh','Hähnchenschenkel','Fleisch','Stück'),
('tuna','Thunfisch','Fisch','g'),('cod','Kabeljau','Fisch','g'),('trout','Forelle','Fisch','g'),('pollock','Seelachs','Fisch','g'),
('shrimp','Garnelen','Fisch','g'),('sardines','Sardinen','Fisch','g'),
('green_beans','Grüne Bohnen','Gemüse','g'),('peas','Erbsen','Gemüse','g'),('corn','Mais','Gemüse','g'),('cauliflower','Blumenkohl','Gemüse','g'),
('zucchini','Zucchini','Gemüse','Stück'),('eggplant','Aubergine','Gemüse','Stück'),('cucumber','Gurke','Gemüse','Stück'),('spinach','Spinat','Gemüse','g'),
('mushrooms','Champignons','Gemüse','g'),('leek','Lauch','Gemüse','Stück'),('red_onion','Rote Zwiebel','Gemüse','Stück'),('celery','Sellerie','Gemüse','g'),
('red_cabbage','Rotkohl','Gemüse','g'),('savoy_cabbage','Wirsing','Gemüse','g'),('brussels_sprouts','Rosenkohl','Gemüse','g'),('pumpkin','Kürbis','Gemüse','g'),
('asparagus','Spargel','Gemüse','g'),('lettuce','Salat','Gemüse','g'),('rocket','Rucola','Gemüse','g'),('avocado','Avocado','Gemüse','Stück'),('ginger','Ingwer','Gemüse','g'),
('pear','Birne','Obst','Stück'),('orange','Orange','Obst','Stück'),('mandarin','Mandarine','Obst','Stück'),('lemon','Zitrone','Obst','Stück'),
('lime','Limette','Obst','Stück'),('strawberry','Erdbeeren','Obst','g'),('raspberry','Himbeeren','Obst','g'),('blueberry','Heidelbeeren','Obst','g'),
('grapes','Trauben','Obst','g'),('pineapple','Ananas','Obst','g'),('mango','Mango','Stück'),('peach','Pfirsich','Stück'),('kiwi','Kiwi','Stück'),
('yogurt','Naturjoghurt','Milchprodukte','g'),('greek_yogurt','Griechischer Joghurt','Milchprodukte','g'),('quark','Quark','Milchprodukte','g'),
('cream_cheese','Frischkäse','Milchprodukte','g'),('creme_fraiche','Crème fraîche','Milchprodukte','g'),('butter','Butter','Milchprodukte','g'),
('gouda','Gouda','Milchprodukte','g'),('cheddar','Cheddar','Milchprodukte','g'),('feta','Feta','Milchprodukte','g'),('mascarpone','Mascarpone','Milchprodukte','g'),
('cottage_cheese','Hüttenkäse','Milchprodukte','g'),('oat_milk','Hafermilch','Milchprodukte','ml'),
('wholegrain_bread','Vollkornbrot','Getreide & Beilagen','Scheiben'),('toast','Toastbrot','Getreide & Beilagen','Scheiben'),
('baguette','Baguette','Getreide & Beilagen','Stück'),('basmati_rice','Basmatireis','Getreide & Beilagen','g'),
('brown_rice','Vollkornreis','Getreide & Beilagen','g'),('risotto_rice','Risottoreis','Getreide & Beilagen','g'),
('couscous','Couscous','Getreide & Beilagen','g'),('bulgur','Bulgur','Getreide & Beilagen','g'),('quinoa','Quinoa','Getreide & Beilagen','g'),
('oats','Haferflocken','Getreide & Beilagen','g'),('breadcrumbs','Semmelbrösel','Getreide & Beilagen','g'),('tortilla','Tortillas','Getreide & Beilagen','Stück'),
('gnocchi','Gnocchi','Getreide & Beilagen','g'),('lasagne_sheets','Lasagneplatten','Getreide & Beilagen','g'),
('kidney_beans','Kidneybohnen','Hülsenfrüchte','g'),('chickpeas','Kichererbsen','Hülsenfrüchte','g'),('lentils','Linsen','Hülsenfrüchte','g'),('white_beans','Weiße Bohnen','Hülsenfrüchte','g'),
('black_beans','Schwarze Bohnen','Hülsenfrüchte','g'),('peanuts','Erdnüsse','Nüsse & Kerne','g'),('almonds','Mandeln','Nüsse & Kerne','g'),
('cashews','Cashews','Nüsse & Kerne','g'),('walnuts','Walnüsse','Nüsse & Kerne','g'),('hazelnuts','Haselnüsse','Nüsse & Kerne','g'),
('pistachios','Pistazien','Nüsse & Kerne','g'),('sunflower_seeds','Sonnenblumenkerne','Nüsse & Kerne','g'),('pumpkin_seeds','Kürbiskerne','Nüsse & Kerne','g'),
('chia_seeds','Chiasamen','Nüsse & Kerne','g'),('paprika_spice','Paprikapulver','Gewürze','g'),('chili','Chili','Gewürze','g'),
('oregano','Oregano','Gewürze','g'),('basil','Basilikum','Gewürze','g'),('parsley','Petersilie','Gewürze','g'),('thyme','Thymian','Gewürze','g'),
('rosemary','Rosmarin','Gewürze','g'),('cumin','Kreuzkümmel','Gewürze','g'),('cinnamon','Zimt','Gewürze','g'),('nutmeg','Muskat','Gewürze','g'),
('turmeric','Kurkuma','Gewürze','g'),('tomato_passata','Passierte Tomaten','Saucen & Grundzutaten','g'),('tomato_paste','Tomatenmark','Saucen & Grundzutaten','g'),
('pesto','Pesto','Saucen & Grundzutaten','g'),('vegetable_stock','Gemüsebrühe','Saucen & Grundzutaten','ml'),('mustard','Senf','Saucen & Grundzutaten','g'),
('mayonnaise','Mayonnaise','Saucen & Grundzutaten','g'),('ketchup','Ketchup','Saucen & Grundzutaten','g'),('vinegar','Essig','Saucen & Grundzutaten','ml'),
('balsamic_vinegar','Balsamico','Saucen & Grundzutaten','ml'),('sugar','Zucker','Backen & Süßes','g'),('cocoa','Kakao','Backen & Süßes','g'),
('baking_powder','Backpulver','Backen & Süßes','g'),('vanilla_sugar','Vanillezucker','Backen & Süßes','Päckchen'),('jam','Marmelade','Backen & Süßes','g')
on conflict (id) do nothing;
