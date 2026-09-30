create extension if not exists pgcrypto;

create type public.food_preference as enum ('like', 'dislike');
create type public.household_role as enum ('owner', 'member');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.household_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.household_role not null default 'member',
  created_at timestamptz not null default now(),
  unique (household_id, user_id)
);

create table public.foods (
  id text primary key,
  name text not null unique,
  category text not null,
  search_terms text[] not null default '{}',
  default_unit text not null default 'Stück',
  created_at timestamptz not null default now()
);

create table public.user_food_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  food_id text not null references public.foods(id) on delete cascade,
  preference public.food_preference not null,
  created_at timestamptz not null default now(),
  unique (user_id, food_id)
);

create table public.recipes (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text not null,
  servings integer not null check (servings > 0),
  prep_time_minutes integer not null check (prep_time_minutes >= 0),
  cook_time_minutes integer not null check (cook_time_minutes >= 0),
  difficulty text not null,
  instructions jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table public.recipe_ingredients (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  food_id text references public.foods(id) on delete set null,
  name text not null,
  quantity numeric not null check (quantity > 0),
  unit text not null,
  is_user_selected boolean not null default false,
  is_additional boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.meal_plans (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  planned_date date not null,
  servings integer not null check (servings > 0),
  created_at timestamptz not null default now()
);

create table public.shopping_lists (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null default 'Gemeinsame Einkaufsliste',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.shopping_list_items (
  id uuid primary key default gen_random_uuid(),
  shopping_list_id uuid not null references public.shopping_lists(id) on delete cascade,
  food_id text references public.foods(id) on delete set null,
  name text not null,
  quantity numeric not null check (quantity > 0),
  unit text not null,
  checked boolean not null default false,
  created_by uuid not null references auth.users(id) on delete cascade,
  source_recipe_id uuid references public.recipes(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_user_food_preferences_user on public.user_food_preferences(user_id);
create index idx_household_members_user on public.household_members(user_id);
create index idx_household_members_household on public.household_members(household_id);
create index idx_meal_plans_household_date on public.meal_plans(household_id, planned_date);
create index idx_shopping_items_list on public.shopping_list_items(shopping_list_id);

create or replace function public.is_household_member(p_household_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.household_members
    where household_id = p_household_id
      and user_id = auth.uid()
  );
$$;

create or replace function public.is_shopping_list_member(p_list_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.shopping_lists sl
    join public.household_members hm
      on hm.household_id = sl.household_id
    where sl.id = p_list_id
      and hm.user_id = auth.uid()
  );
$$;

alter table public.profiles enable row level security;
alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.foods enable row level security;
alter table public.user_food_preferences enable row level security;
alter table public.recipes enable row level security;
alter table public.recipe_ingredients enable row level security;
alter table public.meal_plans enable row level security;
alter table public.shopping_lists enable row level security;
alter table public.shopping_list_items enable row level security;

create policy "profiles own" on public.profiles
for all using (id = auth.uid()) with check (id = auth.uid());

create policy "foods readable by authenticated"
on public.foods for select to authenticated using (true);

create policy "preferences own"
on public.user_food_preferences
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "household members readable"
on public.households for select to authenticated
using (public.is_household_member(id));

create policy "household owners insert"
on public.households for insert to authenticated
with check (created_by = auth.uid());

create policy "household member rows readable"
on public.household_members for select to authenticated
using (public.is_household_member(household_id));

create policy "own household membership insert"
on public.household_members for insert to authenticated
with check (user_id = auth.uid());

create policy "own recipes"
on public.recipes for all to authenticated
using (created_by = auth.uid()) with check (created_by = auth.uid());

create policy "recipe ingredients via own recipe"
on public.recipe_ingredients for all to authenticated
using (
  exists (
    select 1 from public.recipes r
    where r.id = recipe_id and r.created_by = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.recipes r
    where r.id = recipe_id and r.created_by = auth.uid()
  )
);

create policy "meal plans household members"
on public.meal_plans for all to authenticated
using (public.is_household_member(household_id))
with check (public.is_household_member(household_id) and created_by = auth.uid());

create policy "shopping lists household members"
on public.shopping_lists for all to authenticated
using (public.is_household_member(household_id))
with check (public.is_household_member(household_id));

create policy "shopping items household members"
on public.shopping_list_items for all to authenticated
using (public.is_shopping_list_member(shopping_list_id))
with check (public.is_shopping_list_member(shopping_list_id));

-- Create profile automatically after signup.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Seed catalog.
insert into public.foods (id, name, category, default_unit) values
('chicken_breast','Hähnchenbrust','Fleisch','g'),
('ground_beef','Rinderhackfleisch','Fleisch','g'),
('salmon','Lachs','Fisch','g'),
('broccoli','Brokkoli','Gemüse','g'),
('bell_pepper','Paprika','Gemüse','Stück'),
('tomato','Tomate','Gemüse','Stück'),
('onion','Zwiebel','Gemüse','Stück'),
('garlic','Knoblauch','Gemüse','Stück'),
('carrot','Karotte','Gemüse','Stück'),
('potato','Kartoffel','Gemüse','g'),
('apple','Apfel','Obst','Stück'),
('banana','Banane','Obst','Stück'),
('rice','Reis','Getreide','g'),
('pasta','Nudeln','Pasta','g'),
('flour','Mehl','Backen','g'),
('egg','Ei','Milchprodukte','Stück'),
('milk','Milch','Milchprodukte','ml'),
('cream','Sahne','Milchprodukte','ml'),
('parmesan','Parmesan','Milchprodukte','g'),
('mozzarella','Mozzarella','Milchprodukte','g'),
('coconut_milk','Kokosmilch','Konserven','Dose'),
('soy_sauce','Sojasauce','Saucen','ml'),
('honey','Honig','Saucen','g'),
('sesame','Sesam','Gewürze','g'),
('olive_oil','Olivenöl','Saucen','ml'),
('salt','Salz','Gewürze','g'),
('pepper','Pfeffer','Gewürze','g'),
('curry_paste','Currypaste','Saucen','g')
on conflict (id) do nothing;

-- Realtime for collaborative shopping.
alter table public.shopping_list_items replica identity full;
alter table public.shopping_lists replica identity full;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'shopping_list_items'
  ) then
    alter publication supabase_realtime add table public.shopping_list_items;
  end if;
end $$;
