alter table public.recipes
  add column if not exists food_tags text[] not null default '{}'::text[];

comment on column public.recipes.food_tags is
  'Optional recipe food/dietary tags, independent from the recipe category. Supported values: Schwein, Rind, Huhn, Fisch, Vegetarisch.';

-- Conservatively classify existing recipes from their ingredient names.
-- Do not infer vegetarian for recipes containing ambiguous meat-related terms.
with ingredient_text as (
  select r.id,
         lower(coalesce(string_agg(ri.name, ' '), '')) as names
  from public.recipes r
  left join public.recipe_ingredients ri on ri.recipe_id = r.id
  group by r.id
),
classified as (
  select id,
    array_remove(array[
      case when names ~ '(rind|rinder|rindfleisch|beef)' then 'Rind' end,
      case when names ~ '(schwein|schweine|schweinefleisch|pork|pancetta|speck)' then 'Schwein' end,
      case when names ~ '(huhn|hähnchen|haehnchen|chicken|pute|truthahn|poularde)' then 'Huhn' end,
      case when names ~ '(fisch|lachs|thunfisch|forelle|kabeljau|seelachs|garnel|shrimp|meeresfrucht)' then 'Fisch' end
    ], null) as protein_tags,
    names
  from ingredient_text
)
update public.recipes r
set food_tags = case
  when cardinality(c.protein_tags) > 0 then c.protein_tags
  when c.names !~ '(fleisch|wurst|schinken|speck|brühe|bruehe|gelatine|schmalz|fisch|lachs|thunfisch|forelle|kabeljau|seelachs|garnel|shrimp|rind|schwein|huhn|hähnchen|haehnchen|pute|truthahn|lamm|wild|ente|gans)' then array['Vegetarisch']::text[]
  else '{}'::text[]
end
from classified c
where r.id = c.id
  and cardinality(coalesce(r.food_tags, '{}'::text[])) = 0;
