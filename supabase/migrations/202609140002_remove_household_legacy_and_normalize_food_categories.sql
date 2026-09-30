-- v39: the product is intentionally personal, so the old collaboration,
-- meal-planning and shopping-list schema is no longer part of the data model.
drop table if exists public.meal_plans cascade;
drop table if exists public.shopping_list_items cascade;
drop table if exists public.shopping_lists cascade;
drop table if exists public.household_members cascade;
drop table if exists public.households cascade;
drop function if exists public.is_household_member(uuid) cascade;
drop function if exists public.is_shopping_list_member(uuid) cascade;
drop type if exists public.household_role cascade;

-- Keep one stable category vocabulary for both the catalog and custom foods.
update public.foods
set category = case
  when category in ('Getreide', 'Pasta') then 'Getreide & Beilagen'
  when category = 'Backen' then 'Backen & Süßes'
  when category = 'Konserven' then 'Sonstiges'
  when category = 'Saucen' then 'Saucen & Grundzutaten'
  else category
end
where category in ('Getreide', 'Pasta', 'Backen', 'Konserven', 'Saucen');

create index if not exists idx_foods_category_name on public.foods(category, name);
