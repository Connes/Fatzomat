-- V43: recipe workflow hardening, scaled shared shopping and safe collection cleanup.
drop function if exists public.share_recipe_for_today(uuid);
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
  insert into public.shared_recipe_plans(connection_id,recipe_id,shared_by,plan_date,status) values(cid,rid,auth.uid(),current_date,'planned') returning id into pid;
  insert into public.shopping_items(shared_recipe_plan_id,food_id,name,quantity,unit)
    select pid,ri.food_id,ri.name,round((ri.quantity * target_servings::numeric / greatest(base_servings,1))::numeric, 2),ri.unit
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

create or replace function public.update_shared_recipe_status(p_plan_id uuid, p_status text)
returns boolean language plpgsql security definer set search_path=public as $$
begin
  if p_status not in ('planned','shopping','cooked','cancelled') then raise exception 'Ungültiger Status.'; end if;
  update public.shared_recipe_plans set status=p_status where id=p_plan_id and is_connection_member(connection_id);
  return found;
end; $$;
revoke execute on function public.update_shared_recipe_status(uuid,text) from public, anon;
grant execute on function public.update_shared_recipe_status(uuid,text) to authenticated;

create or replace function public.remove_recipe_from_collection(p_recipe_id uuid)
returns boolean language plpgsql security definer set search_path=public as $$
declare owner_id uuid; deleted_recipe boolean := false;
begin
  if auth.uid() is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  select r.created_by into owner_id from public.recipes r where r.id=p_recipe_id and (r.created_by=auth.uid() or exists(select 1 from public.recipe_saves rs where rs.recipe_id=r.id and rs.user_id=auth.uid())) limit 1;
  if owner_id is null then raise exception 'Rezept ist nicht verfügbar.'; end if;
  delete from public.recipe_saves where recipe_id=p_recipe_id and user_id=auth.uid();
  if not exists(select 1 from public.recipe_saves rs where rs.recipe_id=p_recipe_id)
     and not exists(select 1 from public.shared_recipe_plans sp where sp.recipe_id=p_recipe_id and sp.status <> 'cancelled') then
    delete from public.recipes where id=p_recipe_id;
    deleted_recipe := true;
  end if;
  return deleted_recipe;
end; $$;
revoke execute on function public.remove_recipe_from_collection(uuid) from public, anon;
grant execute on function public.remove_recipe_from_collection(uuid) to authenticated;
