create index if not exists idx_recipe_ingredients_recipe_id on public.recipe_ingredients(recipe_id);
create index if not exists idx_recipe_ingredients_food_id on public.recipe_ingredients(food_id);
create index if not exists idx_recipes_created_by on public.recipes(created_by);
create index if not exists idx_user_food_preferences_food_id on public.user_food_preferences(food_id);
