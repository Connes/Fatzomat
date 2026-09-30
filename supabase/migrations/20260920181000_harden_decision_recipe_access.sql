-- A decision participant may only resolve a recipe that is explicitly accessible to that participant.
create or replace function public.resolve_decision_request(
  p_request_id uuid, p_decision_mode text, p_result_type text, p_result_id text, p_servings integer default null
) returns boolean language plpgsql security definer set search_path = public, pg_temp as $$
declare request_row public.decision_requests; target_user uuid; target_plan uuid; previous_recipe uuid; base_servings integer; target_servings integer; action_name text; target_decision_type text;
begin
  if auth.uid() is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  if p_decision_mode is null or p_result_type is null or p_result_id is null or btrim(p_result_id) = '' then raise exception 'Eine vollständige Entscheidung ist erforderlich.'; end if;
  select * into request_row from public.decision_requests dr where dr.id=p_request_id and dr.assigned_to=auth.uid() and dr.status in ('pending','accepted') for update;
  if request_row.id is null then raise exception 'Die Entscheidungsanfrage ist nicht mehr offen.'; end if;
  target_user := request_row.created_by;
  if p_result_type not in ('recipe','order','dine_out','surprise') then raise exception 'Ungültiger Entscheidungstyp.'; end if;
  if p_result_type='recipe' then
    if p_decision_mode <> 'cook' then raise exception 'Ein Rezept kann nur als Kochentscheidung gespeichert werden.'; end if;
    select r.servings into base_servings from public.recipes r where r.id=p_result_id::uuid and (r.created_by=auth.uid() or exists(select 1 from public.recipe_saves rs where rs.recipe_id=r.id and rs.user_id=auth.uid()) or exists(select 1 from public.shared_recipe_plans sp where sp.recipe_id=r.id and public.is_connection_member(sp.connection_id)) or exists(select 1 from public.recipe_suggestions rs where rs.recipe_id=r.id and rs.suggested_to=auth.uid() and rs.status in ('pending','accepted') and public.is_connection_member(rs.connection_id)));
    if base_servings is null then raise exception 'Das ausgewählte Rezept ist für die entscheidende Person nicht freigegeben.'; end if;
    target_servings:=coalesce(p_servings,base_servings); if target_servings<1 or target_servings>12 then raise exception 'Ungültige Personenzahl.'; end if;
    select p.id,p.recipe_id into target_plan,previous_recipe from public.personal_today_plans p where p.user_id=target_user and p.plan_date=current_date and p.status<>'cancelled' limit 1;
    if target_plan is null then
      insert into public.personal_today_plans(user_id,recipe_id,decision_type,decision_value,plan_date,status,servings) values(target_user,p_result_id::uuid,'recipe',null,current_date,'planned',target_servings) returning id into target_plan; action_name:='selected';
    else
      update public.personal_today_plans set recipe_id=p_result_id::uuid,decision_type='recipe',decision_value=null,status='planned',servings=target_servings,updated_at=now() where id=target_plan and user_id=target_user;
      action_name:=case when previous_recipe is distinct from p_result_id::uuid then 'replaced' else 'selected' end;
    end if;
    delete from public.shopping_items where personal_today_plan_id=target_plan and source='recipe';
    insert into public.shopping_items(personal_today_plan_id,food_id,name,quantity,unit,source) select target_plan,ri.food_id,ri.name,round((ri.quantity*target_servings::numeric/greatest(base_servings,1))::numeric,2),ri.unit,'recipe' from public.recipe_ingredients ri where ri.recipe_id=p_result_id::uuid;
    insert into public.personal_decision_history(user_id,plan_id,recipe_id,action,source) values(target_user,target_plan,p_result_id::uuid,action_name,'decision_request');
  else
    target_decision_type:=p_result_type;
    select p.id into target_plan from public.personal_today_plans p where p.user_id=target_user and p.plan_date=current_date and p.status<>'cancelled' limit 1;
    if target_plan is null then
      insert into public.personal_today_plans(user_id,recipe_id,decision_type,decision_value,plan_date,status,servings) values(target_user,null,target_decision_type,btrim(p_result_id),current_date,'planned',1) returning id into target_plan;
    else
      delete from public.shopping_items where personal_today_plan_id=target_plan;
      update public.personal_today_plans set recipe_id=null,decision_type=target_decision_type,decision_value=btrim(p_result_id),status='planned',servings=1,updated_at=now() where id=target_plan and user_id=target_user;
    end if;
    insert into public.personal_decision_history(user_id,plan_id,recipe_id,action,source) values(target_user,target_plan,null,'selected','decision_request');
  end if;
  update public.decision_requests set status='resolved',decision_mode=p_decision_mode,result_type=p_result_type,result_id=p_result_id,resolved_at=now() where id=p_request_id and assigned_to=auth.uid() and status in ('pending','accepted');
  if not found then raise exception 'Die Entscheidungsanfrage ist nicht mehr offen.'; end if;
  insert into public.app_notifications(user_id,type,title,body,decision_request_id,recipe_id) values(target_user,'decision_resolved','Entscheidung getroffen','Deine verbundene Person hat entschieden: '||btrim(p_result_id)||'.',request_row.id,case when p_result_type='recipe' then p_result_id::uuid else null end);
  return true;
end; $$;
revoke all on function public.resolve_decision_request(uuid,text,text,text,integer) from public, anon;
grant execute on function public.resolve_decision_request(uuid,text,text,text,integer) to authenticated;
