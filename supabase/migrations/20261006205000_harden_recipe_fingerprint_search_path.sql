-- Keep the immutable fingerprint helper independent from the caller's search_path.
create or replace function public.recipe_fingerprint(p_recipe jsonb, p_ingredients jsonb)
returns text
language sql
immutable
set search_path = pg_catalog
as $function$
  select md5(
    lower(regexp_replace(trim(coalesce(p_recipe->>'name','')), '\\s+', ' ', 'g'))
    || '|' || coalesce((
      select string_agg(
        lower(regexp_replace(trim(coalesce(item->>'section','')), '\\s+', ' ', 'g'))
        || ':' || lower(regexp_replace(trim(coalesce(item->>'name','')), '\\s+', ' ', 'g'))
        || ':' || coalesce(nullif(item->>'amount','')::numeric, nullif(item->>'quantity','')::numeric, 1)::text
        || ':' || lower(trim(coalesce(item->>'unit',''))),
        '|' order by
          lower(regexp_replace(trim(coalesce(item->>'section','')), '\\s+', ' ', 'g')),
          lower(regexp_replace(trim(coalesce(item->>'name','')), '\\s+', ' ', 'g')),
          coalesce(nullif(item->>'amount','')::numeric, nullif(item->>'quantity','')::numeric, 1),
          lower(trim(coalesce(item->>'unit','')))
      ) from jsonb_array_elements(coalesce(p_ingredients,'[]'::jsonb)) as values(item)
    ), '')
  );
$function$;