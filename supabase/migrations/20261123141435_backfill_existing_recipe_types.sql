-- Fill the recipe type for existing, clearly identifiable saved recipes.
-- Leave unknown types untouched rather than guessing.
update public.recipes
set category = case
  when lower(name) ~ '(tiramisu|cake[[:space:]-]*pops|käsekuchen|kuchen|dessert|pudding|torte|muffin|keks|gebäck)'
    then 'Süßspeise'
  when lower(name) ~ '(burger|gnocchi|nudeln|curry|ragù|ragu|gulasch|auflauf|pfanne)'
       or food_tags && array['Schwein','Rind','Huhn','Fisch']::text[]
    then 'Hauptgericht'
  else category
end
where coalesce(trim(category), '') = ''
  and (
    lower(name) ~ '(tiramisu|cake[[:space:]-]*pops|käsekuchen|kuchen|dessert|pudding|torte|muffin|keks|gebäck|burger|gnocchi|nudeln|curry|ragù|ragu|gulasch|auflauf|pfanne)'
    or food_tags && array['Schwein','Rind','Huhn','Fisch']::text[]
  );
