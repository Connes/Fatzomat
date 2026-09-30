-- V81: editable shared Today plan with synchronized servings and replacement.

alter table public.shared_recipe_plans
  add column if not exists servings integer;

update public.shared_recipe_plans sp
set servings = greatest(coalesce(r.servings, 2), 1)
from public.recipes r
where r.id = sp.recipe_id and sp.servings is null;

alter table public.shared_recipe_plans
  alter column servings set default 2;

alter table public.shared_recipe_plans
  add constraint shared_recipe_plans_servings_check check (servings between 1 and 12);

create or replace function public.update_shared_recipe_plan_servings(p_plan_id uuid, p_servings integer)
returns boolean language plpgsql security definer set search_path=public as $$
declare
  cid uuid;
  rid uuid;
  base_servings integer;
begin
  if auth.uid() is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  if p_servings < 1 or p_servings > 12 then raise exception 'Ungültige Personenzahl.'; end if;
  select connection_id, recipe_id into cid, rid
  from public.shared_recipe_plans
  where id = p_plan_id and plan_date = current_date and status <> 'cancelled';
  if cid is null or not public.is_connection_member(cid) then raise exception 'Tagesplan ist nicht verfügbar.'; end if;
  select servings into base_servings from public.recipes where id = rid;
  if base_servings is null or base_servings < 1 then base_servings := 1; end if;

  update public.shared_recipe_plans set servings = p_servings where id = p_plan_id;
  delete from public.shopping_items where shared_recipe_plan_id = p_plan_id and source = 'recipe';
  insert into public.shopping_items(shared_recipe_plan_id,food_id,name,quantity,unit,source)
    select p_plan_id,ri.food_id,ri.name,round((ri.quantity * p_servings::numeric / greatest(base_servings,1))::numeric, 2),ri.unit,'recipe'
    from public.recipe_ingredients ri where ri.recipe_id=rid;
  return true;
end; $$;
revoke execute on function public.update_shared_recipe_plan_servings(uuid,integer) from public, anon;
grant execute on function public.update_shared_recipe_plan_servings(uuid,integer) to authenticated;

create or replace function public.cancel_shared_recipe_plan(p_plan_id uuid)
returns boolean language plpgsql security definer set search_path=public as $$
begin
  if auth.uid() is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  delete from public.shopping_items where shared_recipe_plan_id = p_plan_id and source = 'recipe';
  update public.shared_recipe_plans set status='cancelled'
    where id=p_plan_id and plan_date=current_date and status <> 'cancelled'
      and public.is_connection_member(connection_id);
  return found;
end; $$;
revoke execute on function public.cancel_shared_recipe_plan(uuid) from public, anon;
grant execute on function public.cancel_shared_recipe_plan(uuid) to authenticated;

create or replace function public.replace_shared_recipe_plan(p_plan_id uuid, p_recipe_id uuid, p_servings integer default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare
  cid uuid;
  target integer;
  base_servings integer;
  partner uuid;
begin
  if auth.uid() is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  select connection_id into cid from public.shared_recipe_plans
    where id=p_plan_id and plan_date=current_date and status <> 'cancelled';
  if cid is null or not public.is_connection_member(cid) then raise exception 'Tagesplan ist nicht verfügbar.'; end if;
  select r.servings into base_servings from public.recipes r
    where r.id=p_recipe_id and (r.created_by=auth.uid() or exists(select 1 from public.recipe_saves rs where rs.recipe_id=r.id and rs.user_id=auth.uid()));
  if base_servings is null then raise exception 'Rezept ist nicht verfügbar.'; end if;
  target := coalesce(p_servings, base_servings);
  if target < 1 or target > 12 then raise exception 'Ungültige Personenzahl.'; end if;

  delete from public.shopping_items where shared_recipe_plan_id = p_plan_id and source = 'recipe';
  update public.shared_recipe_plans
    set recipe_id=p_recipe_id, servings=target, status='planned'
    where id=p_plan_id;
  insert into public.shopping_items(shared_recipe_plan_id,food_id,name,quantity,unit,source)
    select p_plan_id,ri.food_id,ri.name,round((ri.quantity * target::numeric / greatest(base_servings,1))::numeric, 2),ri.unit,'recipe'
    from public.recipe_ingredients ri where ri.recipe_id=p_recipe_id;

  select cm.user_id into partner from public.connection_members cm
    where cm.connection_id=cid and cm.user_id<>auth.uid() limit 1;
  if partner is not null then
    insert into public.app_notifications(user_id,type,title,body,recipe_id,shared_recipe_plan_id)
    select partner,'shared_recipe','Rezept für heute geändert','Euer heutiges Rezept wurde geändert.',p_recipe_id,p_plan_id;
  end if;
  return p_plan_id;
end; $$;
revoke execute on function public.replace_shared_recipe_plan(uuid,uuid,integer) from public, anon;
grant execute on function public.replace_shared_recipe_plan(uuid,uuid,integer) to authenticated;

-- Keep the original creation RPC in sync with the new servings column.
create or replace function public.share_recipe_for_today(p_recipe_id uuid, p_servings integer default null)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare cid uuid; pid uuid; partner uuid; rid uuid; base_servings integer; target_servings integer;
begin
  if auth.uid() is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  select cm.connection_id into cid from public.connection_members cm where cm.user_id=auth.uid() limit 1;
  if cid is null then raise exception 'Keine Verbindung zu einer zweiten Person vorhanden.'; end if;
  select r.id, r.servings into rid, base_servings from public.recipes r
    where r.id=p_recipe_id and (r.created_by=auth.uid() or exists(select 1 from public.recipe_saves rs where rs.recipe_id=r.id and rs.user_id=auth.uid())) limit 1;
  if rid is null then raise exception 'Rezept ist nicht verfügbar.'; end if;
  target_servings := coalesce(p_servings, base_servings);
  if target_servings < 1 or target_servings > 12 then raise exception 'Ungültige Personenzahl.'; end if;
  select sp.id into pid from public.shared_recipe_plans sp where sp.connection_id=cid and sp.plan_date=current_date and sp.status <> 'cancelled';
  if pid is not null then raise exception 'Für heute ist bereits ein gemeinsames Rezept ausgewählt.'; end if;
  insert into public.shared_recipe_plans(connection_id,recipe_id,shared_by,plan_date,status,servings) values(cid,rid,auth.uid(),current_date,'planned',target_servings) returning id into pid;
  insert into public.shopping_items(shared_recipe_plan_id,food_id,name,quantity,unit,source)
    select pid,ri.food_id,ri.name,round((ri.quantity * target_servings::numeric / greatest(base_servings,1))::numeric, 2),ri.unit,'recipe'
    from public.recipe_ingredients ri where ri.recipe_id=rid;
  select cm.user_id into partner from public.connection_members cm where cm.connection_id=cid and cm.user_id<>auth.uid() limit 1;
  if partner is not null then
    insert into public.app_notifications(user_id,type,title,body,recipe_id,shared_recipe_plan_id)
    select partner,'shared_recipe','Neues Rezept für heute',r.name || ' wurde für euch heute ausgewählt.',rid,pid from public.recipes r where r.id=rid;
  end if;
  return pid;
end; $$;
revoke execute on function public.share_recipe_for_today(uuid,integer) from public, anon;
grant execute on function public.share_recipe_for_today(uuid,integer) to authenticated;
