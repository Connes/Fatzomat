-- Personal Today must represent the full personal decision, not only recipes.
alter table public.personal_today_plans
  alter column recipe_id drop not null;

alter table public.personal_today_plans
  add column if not exists decision_type text not null default 'recipe',
  add column if not exists decision_value text;

alter table public.personal_today_plans
  drop constraint if exists personal_today_plans_decision_type_check;
alter table public.personal_today_plans
  add constraint personal_today_plans_decision_type_check
  check (decision_type in ('recipe','order','dine_out','surprise'));

alter table public.personal_today_plans
  drop constraint if exists personal_today_plans_decision_payload_check;
alter table public.personal_today_plans
  add constraint personal_today_plans_decision_payload_check
  check (
    (decision_type = 'recipe' and recipe_id is not null)
    or
    (decision_type in ('order','dine_out','surprise') and recipe_id is null and coalesce(trim(decision_value),'') <> '')
  );

-- Personal Today RLS remains owner-only and validates recipe access when a recipe is used.
drop policy if exists "personal today own insert" on public.personal_today_plans;
drop policy if exists "personal today own update" on public.personal_today_plans;

create policy "personal today own insert" on public.personal_today_plans
for insert to authenticated
with check (
  user_id = (select auth.uid())
  and (
    (decision_type = 'recipe' and exists (
      select 1 from public.recipes r
      where r.id = personal_today_plans.recipe_id
        and (r.created_by = (select auth.uid()) or exists (
          select 1 from public.recipe_saves rs
          where rs.recipe_id = r.id and rs.user_id = (select auth.uid())
        ))
    ))
    or
    (decision_type in ('order','dine_out','surprise') and recipe_id is null and coalesce(trim(decision_value),'') <> '')
  )
);

create policy "personal today own update" on public.personal_today_plans
for update to authenticated
using (user_id = (select auth.uid()))
with check (
  user_id = (select auth.uid())
  and (
    (decision_type = 'recipe' and exists (
      select 1 from public.recipes r
      where r.id = personal_today_plans.recipe_id
        and (r.created_by = (select auth.uid()) or exists (
          select 1 from public.recipe_saves rs
          where rs.recipe_id = r.id and rs.user_id = (select auth.uid())
        ))
    ))
    or
    (decision_type in ('order','dine_out','surprise') and recipe_id is null and coalesce(trim(decision_value),'') <> '')
  )
);

create or replace function public.set_personal_today_decision(p_decision_type text, p_decision_value text)
returns uuid language plpgsql security invoker set search_path=public,pg_temp as $$
declare
  uid uuid := auth.uid();
  pid uuid;
  normalized_type text := lower(trim(p_decision_type));
  normalized_value text := trim(p_decision_value);
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  if normalized_type not in ('order','dine_out','surprise') then raise exception 'Ungültiger persönlicher Entscheidungstyp.'; end if;
  if normalized_value = '' then raise exception 'Die Auswahl darf nicht leer sein.'; end if;

  select id into pid from public.personal_today_plans
  where user_id=uid and plan_date=current_date and status<>'cancelled' limit 1;

  if pid is null then
    insert into public.personal_today_plans(user_id,recipe_id,decision_type,decision_value,plan_date,status,servings)
    values(uid,null,normalized_type,normalized_value,current_date,'planned',1)
    returning id into pid;
  else
    delete from public.shopping_items where personal_today_plan_id=pid;
    update public.personal_today_plans
      set recipe_id=null,decision_type=normalized_type,decision_value=normalized_value,
          status='planned',servings=1,updated_at=now()
      where id=pid and user_id=uid;
  end if;

  insert into public.personal_decision_history(user_id,plan_id,recipe_id,action,source)
  values(uid,pid,null,'selected','today');
  return pid;
end; $$;

revoke all on function public.set_personal_today_decision(text,text) from public,anon;
grant execute on function public.set_personal_today_decision(text,text) to authenticated;

-- Existing recipe selection remains the canonical personal recipe path.
create or replace function public.set_personal_today_plan(p_recipe_id uuid, p_servings integer default null)
returns uuid language plpgsql security invoker set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); pid uuid; previous_recipe uuid; base_servings integer; target_servings integer; action_name text;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  select r.servings into base_servings from public.recipes r
  where r.id=p_recipe_id and (r.created_by=uid or exists(select 1 from public.recipe_saves rs where rs.recipe_id=r.id and rs.user_id=uid));
  if base_servings is null then raise exception 'Rezept ist nicht verfügbar.'; end if;
  target_servings:=coalesce(p_servings,base_servings);
  if target_servings<1 or target_servings>12 then raise exception 'Ungültige Personenzahl.'; end if;

  select p.id,p.recipe_id into pid,previous_recipe from public.personal_today_plans p
  where p.user_id=uid and p.plan_date=current_date and p.status<>'cancelled' limit 1;

  if pid is null then
    insert into public.personal_today_plans(user_id,recipe_id,decision_type,decision_value,plan_date,status,servings)
    values(uid,p_recipe_id,'recipe',null,current_date,'planned',target_servings) returning id into pid;
    action_name:='selected';
  else
    update public.personal_today_plans set recipe_id=p_recipe_id,decision_type='recipe',decision_value=null,status='planned',servings=target_servings,updated_at=now()
    where id=pid and user_id=uid;
    action_name:=case when previous_recipe is distinct from p_recipe_id then 'replaced' else 'selected' end;
  end if;

  delete from public.shopping_items where personal_today_plan_id=pid and source='recipe';
  insert into public.shopping_items(personal_today_plan_id,food_id,name,quantity,unit,source)
  select pid,ri.food_id,ri.name,round((ri.quantity*target_servings::numeric/greatest(base_servings,1))::numeric,2),ri.unit,'recipe'
  from public.recipe_ingredients ri where ri.recipe_id=p_recipe_id;

  insert into public.personal_decision_history(user_id,plan_id,recipe_id,action,source)
  values(uid,pid,p_recipe_id,action_name,'today');
  return pid;
end; $$;

revoke all on function public.set_personal_today_plan(uuid,integer) from public,anon;
grant execute on function public.set_personal_today_plan(uuid,integer) to authenticated;
