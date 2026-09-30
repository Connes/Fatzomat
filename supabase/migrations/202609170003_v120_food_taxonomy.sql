-- V1.2: structured food taxonomy. Display names are no longer the source of truth
-- for dietary/allergen/protein decisions.
alter table public.foods
  add column if not exists aliases text[] not null default '{}',
  add column if not exists dietary_type text not null default 'omnivore',
  add column if not exists allergens text[] not null default '{}',
  add column if not exists protein_type text;

alter table public.foods
  drop constraint if exists foods_dietary_type_check;
alter table public.foods
  add constraint foods_dietary_type_check
  check (dietary_type in ('omnivore', 'vegetarian', 'vegan'));

alter table public.foods
  drop constraint if exists foods_protein_type_check;
alter table public.foods
  add constraint foods_protein_type_check
  check (protein_type is null or protein_type in ('meat', 'fish', 'plant', 'dairy', 'egg'));

create index if not exists idx_foods_dietary_type on public.foods(dietary_type);
create index if not exists idx_foods_protein_type on public.foods(protein_type);

-- Conservative defaults for the existing seed data. These are intentionally
-- category based; individual rows can be refined later without code changes.
update public.foods
set protein_type = 'fish', dietary_type = 'omnivore'
where lower(category) like '%fisch%';

update public.foods
set protein_type = 'meat', dietary_type = 'omnivore'
where lower(category) like '%fleisch%';

update public.foods
set protein_type = 'dairy', dietary_type = 'vegetarian'
where lower(category) like '%milchprodukte%';

update public.foods
set protein_type = 'plant', dietary_type = case
  when lower(category) in ('gemüse', 'obst', 'hülsenfrüchte', 'nüsse & kerne', 'gewürze', 'saucen & grundzutaten') then 'vegan'
  else 'vegetarian'
end
where protein_type is null;

comment on column public.foods.dietary_type is 'Structured dietary classification: omnivore, vegetarian or vegan.';
comment on column public.foods.allergens is 'Structured allergen identifiers, never inferred from display name at runtime.';
comment on column public.foods.protein_type is 'Structured protein family used by recipe/domain rules.';
