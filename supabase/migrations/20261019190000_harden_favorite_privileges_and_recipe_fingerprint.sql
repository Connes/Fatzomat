-- Defense in depth: anonymous API role must not have direct table privileges.
-- Authenticated users remain limited by the own-row RLS policy.
revoke all on table public.restaurant_favorites from public, anon;
grant select, insert, update, delete
  on table public.restaurant_favorites to authenticated;

-- The global recipe library is read-only for non-owners. The broad UPDATE
-- policy bypassed the owner-only predicate in the separate "own recipes"
-- policy because permissive policies are combined with OR.
drop policy if exists "recipes global update" on public.recipes;

-- This immutable helper uses only PostgreSQL built-ins and JSON operators.
-- Pinning the search_path prevents object-shadowing attacks through writable schemas.
create or replace function public.recipe_fingerprint(
  p_recipe jsonb,
  p_ingredients jsonb
)
returns text
language sql
immutable
set search_path = pg_catalog, pg_temp
as $function$
  select md5(
    lower(regexp_replace(trim(coalesce(p_recipe->>'name','')), '\s+', ' ', 'g'))
    || '|' || coalesce((
      select string_agg(
        lower(regexp_replace(trim(coalesce(item->>'name','')), '\s+', ' ', 'g'))
        || ':'
        || coalesce(nullif(item->>'amount','')::numeric, nullif(item->>'quantity','')::numeric, 1)::text
        || ':'
        || lower(trim(coalesce(item->>'unit',''))),
        '|' order by
          lower(regexp_replace(trim(coalesce(item->>'name','')), '\s+', ' ', 'g')),
          coalesce(nullif(item->>'amount','')::numeric, nullif(item->>'quantity','')::numeric, 1),
          lower(trim(coalesce(item->>'unit','')))
      )
      from jsonb_array_elements(coalesce(p_ingredients,'[]'::jsonb)) as values(item)
    ), '')
  );
$function$;
