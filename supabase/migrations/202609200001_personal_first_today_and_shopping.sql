create table if not exists public.personal_today_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  plan_date date not null default current_date,
  status text not null default 'planned' check (status in ('planned','shopping','cooked','cancelled')),
  servings integer not null default 2 check (servings between 1 and 12),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists personal_today_plans_one_active_per_user_day on public.personal_today_plans(user_id, plan_date) where status <> 'cancelled';
create index if not exists idx_personal_today_plans_user_date on public.personal_today_plans(user_id, plan_date desc);
alter table public.personal_today_plans enable row level security;
drop policy if exists "personal today own select" on public.personal_today_plans;
drop policy if exists "personal today own insert" on public.personal_today_plans;
drop policy if exists "personal today own update" on public.personal_today_plans;
drop policy if exists "personal today own delete" on public.personal_today_plans;
create policy "personal today own select" on public.personal_today_plans for select to authenticated using (user_id = (select auth.uid()));
create policy "personal today own insert" on public.personal_today_plans for insert to authenticated with check (user_id = (select auth.uid()));
create policy "personal today own update" on public.personal_today_plans for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "personal today own delete" on public.personal_today_plans for delete to authenticated using (user_id = (select auth.uid()));

alter table public.shopping_items add column if not exists personal_today_plan_id uuid references public.personal_today_plans(id) on delete cascade;
alter table public.shopping_items alter column shared_recipe_plan_id drop not null;
alter table public.shopping_items drop constraint if exists shopping_items_exactly_one_plan;
alter table public.shopping_items add constraint shopping_items_exactly_one_plan check ((personal_today_plan_id is not null) <> (shared_recipe_plan_id is not null));
create index if not exists idx_shopping_items_personal_plan on public.shopping_items(personal_today_plan_id);
alter table public.shopping_items enable row level security;
drop policy if exists "shopping members" on public.shopping_items;
drop policy if exists "shopping member insert" on public.shopping_items;
drop policy if exists "shopping member update" on public.shopping_items;
drop policy if exists "shopping member delete" on public.shopping_items;
drop policy if exists "shopping personal select" on public.shopping_items;
drop policy if exists "shopping personal insert" on public.shopping_items;
drop policy if exists "shopping personal update" on public.shopping_items;
drop policy if exists "shopping personal delete" on public.shopping_items;
create policy "shopping personal select" on public.shopping_items for select to authenticated using (
  (personal_today_plan_id is not null and exists (select 1 from public.personal_today_plans p where p.id=shopping_items.personal_today_plan_id and p.user_id=(select auth.uid())))
  or (shared_recipe_plan_id is not null and exists (select 1 from public.shared_recipe_plans sp where sp.id=shopping_items.shared_recipe_plan_id and public.is_connection_member(sp.connection_id)))
);
create policy "shopping personal insert" on public.shopping_items for insert to authenticated with check (
  (personal_today_plan_id is not null and shared_recipe_plan_id is null and exists (select 1 from public.personal_today_plans p where p.id=shopping_items.personal_today_plan_id and p.user_id=(select auth.uid())))
  or (personal_today_plan_id is null and shared_recipe_plan_id is not null and exists (select 1 from public.shared_recipe_plans sp where sp.id=shopping_items.shared_recipe_plan_id and public.is_connection_member(sp.connection_id)))
);
create policy "shopping personal update" on public.shopping_items for update to authenticated using (
  (personal_today_plan_id is not null and exists (select 1 from public.personal_today_plans p where p.id=shopping_items.personal_today_plan_id and p.user_id=(select auth.uid())))
  or (shared_recipe_plan_id is not null and exists (select 1 from public.shared_recipe_plans sp where sp.id=shopping_items.shared_recipe_plan_id and public.is_connection_member(sp.connection_id)))
) with check (
  (personal_today_plan_id is not null and shared_recipe_plan_id is null and exists (select 1 from public.personal_today_plans p where p.id=shopping_items.personal_today_plan_id and p.user_id=(select auth.uid())))
  or (personal_today_plan_id is null and shared_recipe_plan_id is not null and exists (select 1 from public.shared_recipe_plans sp where sp.id=shopping_items.shared_recipe_plan_id and public.is_connection_member(sp.connection_id)))
);
create policy "shopping personal delete" on public.shopping_items for delete to authenticated using (
  (personal_today_plan_id is not null and exists (select 1 from public.personal_today_plans p where p.id=shopping_items.personal_today_plan_id and p.user_id=(select auth.uid())))
  or (shared_recipe_plan_id is not null and exists (select 1 from public.shared_recipe_plans sp where sp.id=shopping_items.shared_recipe_plan_id and public.is_connection_member(sp.connection_id)))
);

create or replace function public.set_personal_today_plan(p_recipe_id uuid, p_servings integer default null)
returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); pid uuid; base_servings integer; target_servings integer;
begin
 if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
 select r.servings into base_servings from public.recipes r where r.id=p_recipe_id and (r.created_by=uid or exists(select 1 from public.recipe_saves rs where rs.recipe_id=r.id and rs.user_id=uid));
 if base_servings is null then raise exception 'Rezept ist nicht verfügbar.'; end if;
 target_servings:=coalesce(p_servings,base_servings); if target_servings<1 or target_servings>12 then raise exception 'Ungültige Personenzahl.'; end if;
 select p.id into pid from public.personal_today_plans p where p.user_id=uid and p.plan_date=current_date and p.status<>'cancelled' limit 1;
 if pid is null then
   insert into public.personal_today_plans(user_id,recipe_id,plan_date,status,servings) values(uid,p_recipe_id,current_date,'planned',target_servings) returning id into pid;
 else
   update public.personal_today_plans set recipe_id=p_recipe_id,status='planned',servings=target_servings,updated_at=now() where id=pid and user_id=uid;
 end if;
 delete from public.shopping_items where personal_today_plan_id=pid and source='recipe';
 insert into public.shopping_items(personal_today_plan_id,food_id,name,quantity,unit,source)
 select pid,ri.food_id,ri.name,round((ri.quantity*target_servings::numeric/greatest(base_servings,1))::numeric,2),ri.unit,'recipe' from public.recipe_ingredients ri where ri.recipe_id=p_recipe_id;
 return pid;
end; $$;
revoke all on function public.set_personal_today_plan(uuid,integer) from public,anon;
grant execute on function public.set_personal_today_plan(uuid,integer) to authenticated;

create or replace function public.update_personal_today_plan_servings(p_plan_id uuid,p_servings integer)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); rid uuid; base_servings integer;
begin
 if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
 if p_servings<1 or p_servings>12 then raise exception 'Ungültige Personenzahl.'; end if;
 select p.recipe_id into rid from public.personal_today_plans p where p.id=p_plan_id and p.user_id=uid and p.plan_date=current_date and p.status<>'cancelled';
 if rid is null then raise exception 'Persönlicher Tagesplan ist nicht verfügbar.'; end if;
 select r.servings into base_servings from public.recipes r where r.id=rid; base_servings:=greatest(coalesce(base_servings,1),1);
 update public.personal_today_plans set servings=p_servings,updated_at=now() where id=p_plan_id and user_id=uid;
 delete from public.shopping_items where personal_today_plan_id=p_plan_id and source='recipe';
 insert into public.shopping_items(personal_today_plan_id,food_id,name,quantity,unit,source)
 select p_plan_id,ri.food_id,ri.name,round((ri.quantity*p_servings::numeric/base_servings::numeric)::numeric,2),ri.unit,'recipe' from public.recipe_ingredients ri where ri.recipe_id=rid;
 return true;
end; $$;
revoke all on function public.update_personal_today_plan_servings(uuid,integer) from public,anon;
grant execute on function public.update_personal_today_plan_servings(uuid,integer) to authenticated;

create or replace function public.cancel_personal_today_plan(p_plan_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare changed integer; uid uuid:=auth.uid();
begin
 if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
 delete from public.shopping_items where personal_today_plan_id=p_plan_id;
 update public.personal_today_plans set status='cancelled',updated_at=now() where id=p_plan_id and user_id=uid and plan_date=current_date and status<>'cancelled';
 get diagnostics changed=row_count; return changed=1;
end; $$;
revoke all on function public.cancel_personal_today_plan(uuid) from public,anon;
grant execute on function public.cancel_personal_today_plan(uuid) to authenticated;

create or replace function public.update_personal_today_status(p_plan_id uuid,p_status text)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare changed integer;
begin
 if auth.uid() is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
 if p_status not in ('planned','shopping','cooked','cancelled') then raise exception 'Ungültiger Status.'; end if;
 update public.personal_today_plans set status=p_status,updated_at=now() where id=p_plan_id and user_id=auth.uid() and plan_date=current_date;
 get diagnostics changed=row_count; return changed=1;
end; $$;
revoke all on function public.update_personal_today_status(uuid,text) from public,anon;
grant execute on function public.update_personal_today_status(uuid,text) to authenticated;

-- A connection does not grant blanket recipe access. Explicitly shared plans
-- still make the referenced recipe readable to connection members.
drop policy if exists "recipes collection read" on public.recipes;
drop policy if exists "recipes owner or shared" on public.recipes;
create policy "recipes personal or explicitly shared read" on public.recipes for select to authenticated using (
 created_by=(select auth.uid())
 or exists(select 1 from public.recipe_saves rs where rs.recipe_id=recipes.id and rs.user_id=(select auth.uid()))
 or exists(select 1 from public.shared_recipe_plans sp where sp.recipe_id=recipes.id and public.is_connection_member(sp.connection_id))
);

drop policy if exists "recipe saves shared" on public.recipe_saves;
drop policy if exists "recipe saves own read" on public.recipe_saves;
create policy "recipe saves own read" on public.recipe_saves for select to authenticated using (user_id=(select auth.uid()));

drop policy if exists "recipe ingredients readable for collection" on public.recipe_ingredients;
create policy "recipe ingredients personal or explicitly shared read" on public.recipe_ingredients for select to authenticated using (
 exists(select 1 from public.recipes r where r.id=recipe_ingredients.recipe_id and (
   r.created_by=(select auth.uid())
   or exists(select 1 from public.recipe_saves rs where rs.recipe_id=r.id and rs.user_id=(select auth.uid()))
   or exists(select 1 from public.shared_recipe_plans sp where sp.recipe_id=r.id and public.is_connection_member(sp.connection_id))
 ))
);

alter publication supabase_realtime add table public.personal_today_plans;
