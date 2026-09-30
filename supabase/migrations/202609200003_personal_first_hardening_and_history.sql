-- Personal-first hardening: enforce recipe access at the table boundary,
-- record personal Today actions, and expose the existing optional recipe image.

alter table public.recipes
  add column if not exists image_url text;

-- Personal decision history is private and independent from collaboration.
create table if not exists public.personal_decision_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_id uuid references public.personal_today_plans(id) on delete set null,
  recipe_id uuid references public.recipes(id) on delete set null,
  action text not null check (action in ('selected','replaced','servings_changed','status_changed','cancelled')),
  source text not null default 'today',
  created_at timestamptz not null default now()
);

create index if not exists idx_personal_decision_history_user_created
  on public.personal_decision_history(user_id, created_at desc);
create index if not exists idx_personal_decision_history_recipe
  on public.personal_decision_history(recipe_id);

alter table public.personal_decision_history enable row level security;
drop policy if exists "personal history own select" on public.personal_decision_history;
drop policy if exists "personal history own insert" on public.personal_decision_history;
drop policy if exists "personal history own delete" on public.personal_decision_history;
create policy "personal history own select" on public.personal_decision_history
  for select to authenticated using (user_id = (select auth.uid()));
create policy "personal history own insert" on public.personal_decision_history
  for insert to authenticated with check (user_id = (select auth.uid()));
create policy "personal history own delete" on public.personal_decision_history
  for delete to authenticated using (user_id = (select auth.uid()));

grant select, insert, delete on public.personal_decision_history to authenticated;

-- A personal TodayPlan may only reference an owned or personally saved recipe.
drop policy if exists "personal today own insert" on public.personal_today_plans;
drop policy if exists "personal today own update" on public.personal_today_plans;
create policy "personal today own insert" on public.personal_today_plans
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1
      from public.recipes r
      where r.id = personal_today_plans.recipe_id
        and (
          r.created_by = (select auth.uid())
          or exists (
            select 1 from public.recipe_saves rs
            where rs.recipe_id = r.id and rs.user_id = (select auth.uid())
          )
        )
    )
  );
create policy "personal today own update" on public.personal_today_plans
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1
      from public.recipes r
      where r.id = personal_today_plans.recipe_id
        and (
          r.created_by = (select auth.uid())
          or exists (
            select 1 from public.recipe_saves rs
            where rs.recipe_id = r.id and rs.user_id = (select auth.uid())
          )
        )
    )
  );

-- A shared plan still requires membership, and the acting member must have
-- legitimate personal access to the recipe being introduced into the plan.
drop policy if exists "shared plans own insert" on public.shared_recipe_plans;
drop policy if exists "shared plans member update" on public.shared_recipe_plans;
create policy "shared plans own insert" on public.shared_recipe_plans
  for insert to authenticated
  with check (
    shared_by = (select auth.uid())
    and public.is_connection_member(connection_id)
    and exists (
      select 1 from public.recipes r
      where r.id = shared_recipe_plans.recipe_id
        and (
          r.created_by = (select auth.uid())
          or exists (
            select 1 from public.recipe_saves rs
            where rs.recipe_id = r.id and rs.user_id = (select auth.uid())
          )
        )
    )
  );
create policy "shared plans member update" on public.shared_recipe_plans
  for update to authenticated
  using (public.is_connection_member(connection_id))
  with check (
    public.is_connection_member(connection_id)
    and exists (
      select 1 from public.recipes r
      where r.id = shared_recipe_plans.recipe_id
        and (
          r.created_by = (select auth.uid())
          or exists (
            select 1 from public.recipe_saves rs
            where rs.recipe_id = r.id and rs.user_id = (select auth.uid())
          )
        )
    )
  );

-- Keep the existing invoker security boundary while recording personal actions.
create or replace function public.set_personal_today_plan(p_recipe_id uuid, p_servings integer default null)
returns uuid language plpgsql security invoker set search_path=public,pg_temp as $$
declare
  uid uuid := auth.uid();
  pid uuid;
  previous_recipe uuid;
  base_servings integer;
  target_servings integer;
  action_name text;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  select r.servings into base_servings
    from public.recipes r
    where r.id=p_recipe_id
      and (r.created_by=uid or exists(select 1 from public.recipe_saves rs where rs.recipe_id=r.id and rs.user_id=uid));
  if base_servings is null then raise exception 'Rezept ist nicht verfügbar.'; end if;
  target_servings:=coalesce(p_servings,base_servings);
  if target_servings<1 or target_servings>12 then raise exception 'Ungültige Personenzahl.'; end if;

  select p.id,p.recipe_id into pid,previous_recipe
    from public.personal_today_plans p
    where p.user_id=uid and p.plan_date=current_date and p.status<>'cancelled'
    limit 1;

  if pid is null then
    insert into public.personal_today_plans(user_id,recipe_id,plan_date,status,servings)
    values(uid,p_recipe_id,current_date,'planned',target_servings)
    returning id into pid;
    action_name := 'selected';
  else
    update public.personal_today_plans
      set recipe_id=p_recipe_id,status='planned',servings=target_servings,updated_at=now()
      where id=pid and user_id=uid;
    action_name := case when previous_recipe is distinct from p_recipe_id then 'replaced' else 'selected' end;
  end if;

  delete from public.shopping_items where personal_today_plan_id=pid and source='recipe';
  insert into public.shopping_items(personal_today_plan_id,food_id,name,quantity,unit,source)
  select pid,ri.food_id,ri.name,round((ri.quantity*target_servings::numeric/greatest(base_servings,1))::numeric,2),ri.unit,'recipe'
  from public.recipe_ingredients ri where ri.recipe_id=p_recipe_id;

  insert into public.personal_decision_history(user_id,plan_id,recipe_id,action,source)
  values(uid,pid,p_recipe_id,action_name,'today');
  return pid;
end; $$;

create or replace function public.update_personal_today_plan_servings(p_plan_id uuid,p_servings integer)
returns boolean language plpgsql security invoker set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); rid uuid; base_servings integer; changed integer;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  if p_servings<1 or p_servings>12 then raise exception 'Ungültige Personenzahl.'; end if;
  select p.recipe_id into rid from public.personal_today_plans p where p.id=p_plan_id and p.user_id=uid and p.plan_date=current_date and p.status<>'cancelled';
  if rid is null then raise exception 'Persönlicher Tagesplan ist nicht verfügbar.'; end if;
  select r.servings into base_servings from public.recipes r where r.id=rid and (r.created_by=uid or exists(select 1 from public.recipe_saves rs where rs.recipe_id=r.id and rs.user_id=uid));
  if base_servings is null then raise exception 'Rezept ist nicht verfügbar.'; end if;
  update public.personal_today_plans set servings=p_servings,updated_at=now() where id=p_plan_id and user_id=uid;
  get diagnostics changed=row_count;
  if changed=1 then
    delete from public.shopping_items where personal_today_plan_id=p_plan_id and source='recipe';
    insert into public.shopping_items(personal_today_plan_id,food_id,name,quantity,unit,source)
    select p_plan_id,ri.food_id,ri.name,round((ri.quantity*p_servings::numeric/greatest(base_servings,1))::numeric,2),ri.unit,'recipe'
    from public.recipe_ingredients ri where ri.recipe_id=rid;
    insert into public.personal_decision_history(user_id,plan_id,recipe_id,action,source)
    values(uid,p_plan_id,rid,'servings_changed','today');
  end if;
  return changed=1;
end; $$;

create or replace function public.cancel_personal_today_plan(p_plan_id uuid)
returns boolean language plpgsql security invoker set search_path=public,pg_temp as $$
declare changed integer; uid uuid:=auth.uid(); rid uuid;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  select recipe_id into rid from public.personal_today_plans where id=p_plan_id and user_id=uid and plan_date=current_date and status<>'cancelled';
  if rid is null then return false; end if;
  delete from public.shopping_items where personal_today_plan_id=p_plan_id;
  update public.personal_today_plans set status='cancelled',updated_at=now() where id=p_plan_id and user_id=uid and plan_date=current_date and status<>'cancelled';
  get diagnostics changed=row_count;
  if changed=1 then
    insert into public.personal_decision_history(user_id,plan_id,recipe_id,action,source)
    values(uid,p_plan_id,rid,'cancelled','today');
  end if;
  return changed=1;
end; $$;

create or replace function public.update_personal_today_status(p_plan_id uuid,p_status text)
returns boolean language plpgsql security invoker set search_path=public,pg_temp as $$
declare changed integer; uid uuid:=auth.uid(); rid uuid;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  if p_status not in ('planned','shopping','cooked','cancelled') then raise exception 'Ungültiger Status.'; end if;
  select recipe_id into rid from public.personal_today_plans where id=p_plan_id and user_id=uid and plan_date=current_date;
  if rid is null then raise exception 'Persönlicher Tagesplan ist nicht verfügbar.'; end if;
  update public.personal_today_plans set status=p_status,updated_at=now() where id=p_plan_id and user_id=uid and plan_date=current_date;
  get diagnostics changed=row_count;
  if changed=1 then
    insert into public.personal_decision_history(user_id,plan_id,recipe_id,action,source)
    values(uid,p_plan_id,rid,case when p_status='cancelled' then 'cancelled' else 'status_changed' end,'today');
  end if;
  return changed=1;
end; $$;

-- Preserve existing grants and invoker semantics.
revoke all on function public.set_personal_today_plan(uuid,integer) from public,anon;
grant execute on function public.set_personal_today_plan(uuid,integer) to authenticated;
revoke all on function public.update_personal_today_plan_servings(uuid,integer) from public,anon;
grant execute on function public.update_personal_today_plan_servings(uuid,integer) to authenticated;
revoke all on function public.cancel_personal_today_plan(uuid) from public,anon;
grant execute on function public.cancel_personal_today_plan(uuid) to authenticated;
revoke all on function public.update_personal_today_status(uuid,text) from public,anon;
grant execute on function public.update_personal_today_status(uuid,text) to authenticated;

-- Persist optional recipe image URLs through the existing personal recipe RPC.
create or replace function public.save_recipe_with_ingredients(
  p_recipe jsonb,
  p_ingredients jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare rid uuid; uid uuid := auth.uid(); item jsonb; ingredient_name text; ingredient_quantity numeric; ingredient_unit text;
begin
  if uid is null then raise exception 'Nicht authentifiziert.'; end if;
  if jsonb_typeof(p_recipe) <> 'object' then raise exception 'Ungültige Rezeptdaten.'; end if;
  if jsonb_typeof(p_ingredients) <> 'array' then raise exception 'Ungültige Zutatenliste.'; end if;
  if coalesce(trim(p_recipe->>'name'),'') = '' then raise exception 'Ein Rezeptname ist erforderlich.'; end if;
  insert into public.recipes(created_by,name,description,servings,prep_time_minutes,cook_time_minutes,difficulty,instructions,image_url)
  values(uid,trim(p_recipe->>'name'),coalesce(p_recipe->>'description',''),greatest(coalesce((p_recipe->>'servings')::integer,1),1),greatest(coalesce((p_recipe->>'prep_time_minutes')::integer,0),0),greatest(coalesce((p_recipe->>'cook_time_minutes')::integer,0),0),coalesce(nullif(trim(p_recipe->>'difficulty'),''),'Einfach'),coalesce(p_recipe->'instructions','[]'::jsonb),nullif(trim(p_recipe->>'image_url'),''))
  returning id into rid;
  for item in select value from jsonb_array_elements(p_ingredients) loop
    ingredient_name:=trim(coalesce(item->>'name','')); ingredient_quantity:=(item->>'quantity')::numeric; ingredient_unit:=coalesce(item->>'unit','');
    if ingredient_name='' then raise exception 'Eine Zutat benötigt einen Namen.'; end if;
    if ingredient_quantity is null or ingredient_quantity<=0 then raise exception 'Zutatenmengen müssen positiv sein.'; end if;
    if ingredient_unit='' then raise exception 'Eine Zutat benötigt eine Einheit.'; end if;
    insert into public.recipe_ingredients(recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative)
    values(rid,nullif(item->>'food_id',''),ingredient_name,ingredient_quantity,ingredient_unit,coalesce((item->>'is_user_selected')::boolean,false),coalesce((item->>'is_additional')::boolean,false),coalesce((item->>'is_qualitative')::boolean,false));
  end loop;
  insert into public.recipe_saves(recipe_id,user_id) values(rid,uid) on conflict do nothing;
  return rid;
end; $$;
revoke all on function public.save_recipe_with_ingredients(jsonb,jsonb) from public,anon;
grant execute on function public.save_recipe_with_ingredients(jsonb,jsonb) to authenticated;
