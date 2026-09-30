-- v40: recipe actions used by the collaboration UI.
-- These functions are already present in the live project; this file keeps
-- the local migration history reproducible.

create or replace function public.add_favorite_recipe(
  p_name text,
  p_description text default '',
  p_instructions jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare rid uuid;
begin
  if trim(coalesce(p_name,''))='' then
    raise exception 'Ein Rezeptname ist erforderlich.';
  end if;

  insert into public.recipes(
    created_by, name, description, servings, prep_time_minutes,
    cook_time_minutes, difficulty, instructions
  )
  values(
    auth.uid(), trim(p_name), coalesce(p_description,''), 2, 0, 0,
    'easy', p_instructions
  )
  returning id into rid;

  insert into public.recipe_saves(recipe_id,user_id)
  values(rid,auth.uid())
  on conflict do nothing;

  return rid;
end;
$$;

create or replace function public.share_recipe_for_today(p_recipe_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  cid uuid;
  pid uuid;
  partner uuid;
  rid uuid;
begin
  select cm.connection_id into cid
  from public.connection_members cm
  where cm.user_id=auth.uid()
  limit 1;

  if cid is null then
    raise exception 'Keine Verbindung zu einer zweiten Person vorhanden.';
  end if;

  select r.id into rid
  from public.recipes r
  where r.id=p_recipe_id
    and (
      r.created_by=auth.uid()
      or exists(
        select 1 from public.recipe_saves rs
        where rs.recipe_id=r.id and rs.user_id=auth.uid()
      )
    )
  limit 1;

  if rid is null then
    raise exception 'Rezept ist nicht verfügbar.';
  end if;

  select sp.id into pid
  from public.shared_recipe_plans sp
  where sp.connection_id=cid and sp.plan_date=current_date;

  if pid is not null then
    raise exception 'Für heute ist bereits ein gemeinsames Rezept ausgewählt.';
  end if;

  insert into public.shared_recipe_plans(
    connection_id, recipe_id, shared_by, plan_date, status
  )
  values(cid,rid,auth.uid(),current_date,'planned')
  returning id into pid;

  insert into public.shopping_items(
    shared_recipe_plan_id,food_id,name,quantity,unit
  )
  select pid,ri.food_id,ri.name,ri.quantity,ri.unit
  from public.recipe_ingredients ri
  where ri.recipe_id=rid;

  select cm.user_id into partner
  from public.connection_members cm
  where cm.connection_id=cid and cm.user_id<>auth.uid()
  limit 1;

  if partner is not null then
    insert into public.app_notifications(
      user_id,type,title,body,recipe_id,shared_recipe_plan_id
    )
    select
      partner,
      'shared_recipe',
      'Neues Rezept für heute',
      r.name || ' wurde für euch heute ausgewählt.',
      rid,
      pid
    from public.recipes r
    where r.id=rid;
  end if;

  return pid;
end;
$$;

revoke execute on function public.add_favorite_recipe(text,text,jsonb) from public, anon;
grant execute on function public.add_favorite_recipe(text,text,jsonb) to authenticated;

revoke execute on function public.share_recipe_for_today(uuid) from public, anon;
grant execute on function public.share_recipe_for_today(uuid) to authenticated;
