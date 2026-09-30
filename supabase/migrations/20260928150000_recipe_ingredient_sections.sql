-- Preserve visible ingredient groups such as "Teig", "Füllung" and "Belag".
alter table public.recipe_ingredients
  add column if not exists section text;
