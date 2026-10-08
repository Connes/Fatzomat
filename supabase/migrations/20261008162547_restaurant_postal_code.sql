drop function if exists public.search_restaurants(double precision, double precision, text, boolean, integer, double precision);

create or replace function public.search_restaurants(
  p_lat double precision,
  p_lon double precision,
  p_cuisine text,
  p_delivery_only boolean default false,
  p_limit integer default 10,
  p_radius_km double precision default 10
)
returns table (
  id text,
  name text,
  address text,
  postal_code text,
  city text,
  distance_km double precision,
  latitude double precision,
  longitude double precision,
  phone text,
  website text,
  order_url text,
  opening_hours text,
  delivery_available boolean,
  cuisine text
)
language sql
stable
set search_path = public, extensions
as $$
  with requested as (
    select case p_cuisine
      when 'Italienisch' then array['italian']::text[]
      when 'Griechisch' then array['greek']::text[]
      when 'Türkisch' then array['turkish']::text[]
      when 'Japanisch' then array['japanese']::text[]
      when 'Chinesisch' then array['chinese']::text[]
      when 'Thailändisch' then array['thai']::text[]
      when 'Vietnamesisch' then array['vietnamese']::text[]
      when 'Koreanisch' then array['korean']::text[]
      when 'Indonesisch' then array['indonesian']::text[]
      when 'Malaysisch' then array['malaysian']::text[]
      when 'Indisch' then array['indian']::text[]
      when 'Burger' then array['burger']::text[]
      when 'Mexikanisch' then array['mexican']::text[]
      when 'Spanisch' then array['spanish']::text[]
      when 'Libanesisch' then array['lebanese']::text[]
      when 'Portugiesisch' then array['portuguese']::text[]
      when 'Vegetarisch' then array['vegetarian']::text[]
      when 'Vegan' then array['vegan']::text[]
      when 'Sushi' then array['sushi']::text[]
      when 'Pizza' then array['pizza','italian_pizza']::text[]
      when 'Döner' then array['kebab','doner','döner']::text[]
      when 'Steak' then array['steak','steak_house']::text[]
      when 'Asiatisch' then array['asian','chinese','thai','vietnamese','korean','indonesian','malaysian']::text[]
      else array[]::text[]
    end as values
  ),
  origin as (
    select extensions.st_setsrid(
      extensions.st_makepoint(p_lon, p_lat), 4326
    )::extensions.geography as point
  )
  select
    r.id::text,
    r.name,
    r.address,
    coalesce(
      nullif(r.metadata #>> '{osm_tags,addr:postcode}', ''),
      nullif(r.metadata ->> 'overture_postcode', '')
    ) as postal_code,
    r.city,
    round((extensions.st_distance(r.location, o.point) / 1000.0)::numeric, 2)::double precision as distance_km,
    r.latitude,
    r.longitude,
    r.phone,
    r.website,
    r.order_url,
    r.opening_hours,
    r.delivery_available,
    nullif(array_to_string(r.cuisine, ';'), '') as cuisine
  from public.restaurant_index r
  cross join origin o
  cross join requested q
  where extensions.st_dwithin(r.location, o.point, greatest(0, p_radius_km) * 1000.0)
    and (p_cuisine = 'Überrasch mich' or r.cuisine && q.values)
    and (not p_delivery_only or r.delivery_available)
  order by extensions.st_distance(r.location, o.point), r.id
  limit least(greatest(p_limit, 1), 50);
$$;

grant execute on function public.search_restaurants(double precision, double precision, text, boolean, integer, double precision) to authenticated;
