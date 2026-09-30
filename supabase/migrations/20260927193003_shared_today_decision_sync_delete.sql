-- Shared Today decision lifecycle.
-- A concrete personal Today plan may be shared once while active.
-- Acceptance links both personal plans. Cancelling either side cancels both
-- and creates a partner notification.

alter table public.decision_shares
  add column if not exists accepted_plan_id uuid
    references public.personal_today_plans(id) on delete set null,
  add column if not exists cancelled_at timestamptz,
  add column if not exists cancelled_by uuid references auth.users(id) on delete set null;

drop index if exists public.uq_decision_shares_one_share_per_sender_day;
drop index if exists public.uq_decision_shares_one_share_per_plan;

create unique index if not exists uq_decision_shares_one_active_share_per_plan
  on public.decision_shares(sender_id, source_plan_id)
  where message_type='share' and source_plan_id is not null and cancelled_at is null;

create or replace function public.send_decision_message(
  p_message_type text,
  p_decision_type text default null,
  p_decision_value text default null,
  p_decision_name text default null,
  p_image_url text default null,
  p_recipe_id uuid default null,
  p_servings integer default null
)
returns uuid language plpgsql security definer set search_path=public,pg_temp
as $$
declare uid uuid:=auth.uid(); cid uuid; partner uuid; share_id uuid; sender_name text; current_plan record; decision_label text;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  if p_message_type not in ('ask','share') then raise exception 'Ungültiger Nachrichtentyp.'; end if;
  select connection_id into cid from public.connection_members where user_id=uid limit 1;
  if cid is null then raise exception 'Keine Verbindung zu einer zweiten Person vorhanden.'; end if;
  select user_id into partner from public.connection_members where connection_id=cid and user_id<>uid limit 1;
  if partner is null then raise exception 'Keine zweite Person ist verbunden.'; end if;
  select nullif(btrim(display_name),'') into sender_name from public.profiles where id=uid;

  if p_message_type='share' then
    select p.id,p.plan_date,p.decision_type,p.decision_value,p.servings into current_plan
    from public.personal_today_plans p
    where p.user_id=uid and p.plan_date=current_date and p.status<>'cancelled'
    order by p.updated_at desc nulls last limit 1;
    if not found then raise exception 'Du hast für heute noch keine persönliche Entscheidung getroffen.'; end if;
    if exists (select 1 from public.decision_shares ds where ds.sender_id=uid and ds.source_plan_id=current_plan.id and ds.message_type='share' and ds.cancelled_at is null) then
      raise exception 'Diese Tagesentscheidung wurde bereits geteilt. Sie kann nur einmal geteilt werden.';
    end if;
    if current_plan.decision_type<>p_decision_type then raise exception 'Deine heutige Entscheidung hat sich geändert. Bitte öffne Heute neu.'; end if;
    decision_label:=coalesce(nullif(btrim(p_decision_name),''),nullif(btrim(p_decision_value),''));
    if decision_label is null then raise exception 'Deine heutige Entscheidung konnte nicht gelesen werden.'; end if;
    if p_decision_type='recipe' and p_recipe_id is null then raise exception 'Die Rezeptentscheidung konnte nicht gelesen werden.'; end if;
    if p_decision_type<>'recipe' and nullif(btrim(p_decision_value),'') is null then raise exception 'Die heutige Auswahl konnte nicht gelesen werden.'; end if;
  end if;

  insert into public.decision_shares(connection_id,sender_id,recipient_id,message_type,plan_date,source_plan_id,decision_type,decision_value,decision_name,image_url,recipe_id,servings)
  values (cid,uid,partner,p_message_type,current_date,case when p_message_type='share' then current_plan.id else null end,
    case when p_message_type='share' then p_decision_type else null end,
    case when p_message_type='share' then nullif(btrim(p_decision_value),'') else null end,
    case when p_message_type='share' then decision_label else null end,
    case when p_message_type='share' then nullif(btrim(p_image_url),'') else null end,
    case when p_message_type='share' then p_recipe_id else null end,
    case when p_message_type='share' then p_servings else null end)
  returning id into share_id;

  insert into public.app_notifications(user_id,type,title,body,decision_share_id)
  values(partner,'decision_message',case when p_message_type='share' then 'Entscheidung geteilt' else 'Entscheide Du' end,
    case when p_message_type='share' then coalesce(sender_name,'Deine verbundene Person') || ' hat heute „' || decision_label || '“ gewählt.' else coalesce(sender_name,'Deine verbundene Person') || ' möchte, dass du heute deine persönliche Essensentscheidung triffst.' end,
    share_id);
  return share_id;
exception when unique_violation then raise exception 'Diese Tagesentscheidung wurde bereits geteilt. Sie kann nur einmal geteilt werden.';
end; $$;

revoke all on function public.send_decision_message(text,text,text,text,text,uuid,integer) from public,anon;
grant execute on function public.send_decision_message(text,text,text,text,text,uuid,integer) to authenticated;

create or replace function public.accept_decision_share(p_share_id uuid)
returns jsonb language plpgsql security definer set search_path=public,pg_temp
as $$
declare uid uuid:=auth.uid(); share_row public.decision_shares; source_recipe public.recipes; copied_recipe_id uuid; plan_id uuid;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  select * into share_row from public.decision_shares where id=p_share_id and recipient_id=uid and is_connection_member(connection_id) for update;
  if share_row.id is null then raise exception 'Die geteilte Entscheidung ist nicht mehr verfügbar.'; end if;
  if share_row.message_type<>'share' then raise exception 'Diese Nachricht enthält keine übernehmbare Entscheidung.'; end if;
  if share_row.cancelled_at is not null then raise exception 'Diese gemeinsame Entscheidung wurde bereits entfernt.'; end if;
  if share_row.plan_date<>current_date then raise exception 'Die geteilte Entscheidung gilt nicht mehr für heute.'; end if;
  if share_row.accepted_at is not null and share_row.accepted_plan_id is not null then
    return jsonb_build_object('share_id',share_row.id,'plan_id',share_row.accepted_plan_id,'decision_type',share_row.decision_type,'recipe_id',share_row.accepted_recipe_id);
  end if;

  if share_row.decision_type='recipe' then
    if share_row.recipe_id is null then raise exception 'Das geteilte Rezept ist nicht mehr verfügbar.'; end if;
    copied_recipe_id:=share_row.accepted_recipe_id;
    if copied_recipe_id is null then
      select * into source_recipe from public.recipes where id=share_row.recipe_id and created_by=share_row.sender_id for share;
      if source_recipe.id is null then raise exception 'Das geteilte Rezept ist nicht mehr verfügbar.'; end if;
      insert into public.recipes(created_by,name,description,servings,prep_time_minutes,cook_time_minutes,difficulty,instructions,image_url)
      values(uid,source_recipe.name,source_recipe.description,source_recipe.servings,source_recipe.prep_time_minutes,source_recipe.cook_time_minutes,source_recipe.difficulty,source_recipe.instructions,source_recipe.image_url)
      returning id into copied_recipe_id;
      insert into public.recipe_ingredients(recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative)
      select copied_recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative from public.recipe_ingredients where recipe_id=share_row.recipe_id;
      insert into public.recipe_saves(recipe_id,user_id) values(copied_recipe_id,uid) on conflict(recipe_id,user_id) do nothing;
    end if;
    plan_id:=public.set_personal_today_plan(copied_recipe_id,share_row.servings);
  elsif share_row.decision_type in ('order','dine_out','surprise') then
    if nullif(btrim(share_row.decision_value),'') is null then raise exception 'Die geteilte Entscheidung ist nicht mehr vollständig verfügbar.'; end if;
    plan_id:=public.set_personal_today_decision(share_row.decision_type,share_row.decision_value);
  else raise exception 'Ungültige geteilte Entscheidung.'; end if;

  update public.decision_shares set accepted_at=now(),accepted_plan_id=plan_id where id=share_row.id;
  return jsonb_build_object('share_id',share_row.id,'plan_id',plan_id,'decision_type',share_row.decision_type,'recipe_id',copied_recipe_id);
end; $$;

revoke all on function public.accept_decision_share(uuid) from public,anon;
grant execute on function public.accept_decision_share(uuid) to authenticated;

create or replace function public.cancel_personal_today_plan(p_plan_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp
as $$
declare uid uuid:=auth.uid(); changed integer:=0; rid uuid; partner_plan_id uuid; share_row public.decision_shares; partner uuid;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  select recipe_id into rid from public.personal_today_plans where id=p_plan_id and user_id=uid and plan_date=current_date and status<>'cancelled';
  if not found then return false; end if;

  select * into share_row from public.decision_shares
  where message_type='share' and cancelled_at is null and (source_plan_id=p_plan_id or accepted_plan_id=p_plan_id)
  order by created_at desc limit 1 for update;

  if share_row.id is not null then
    partner:=case when share_row.sender_id=uid then share_row.recipient_id else share_row.sender_id end;
    partner_plan_id:=case when share_row.sender_id=uid then share_row.accepted_plan_id else share_row.source_plan_id end;
    update public.decision_shares set cancelled_at=now(),cancelled_by=uid where id=share_row.id;
    if partner_plan_id is not null then
      delete from public.shopping_items where personal_today_plan_id=partner_plan_id;
      update public.personal_today_plans set status='cancelled',updated_at=now() where id=partner_plan_id and user_id=partner and plan_date=current_date and status<>'cancelled';
      insert into public.app_notifications(user_id,type,title,body,decision_share_id)
      values(partner,'decision_shared_deleted','Gemeinsame Entscheidung entfernt','Die gemeinsame Tagesentscheidung wurde von deiner verbundenen Person entfernt.',share_row.id);
    end if;
  end if;

  delete from public.shopping_items where personal_today_plan_id=p_plan_id;
  update public.personal_today_plans set status='cancelled',updated_at=now() where id=p_plan_id and user_id=uid and plan_date=current_date and status<>'cancelled';
  get diagnostics changed=row_count;
  if changed=1 then insert into public.personal_decision_history(user_id,plan_id,recipe_id,action,source) values(uid,p_plan_id,rid,'cancelled','today'); end if;
  return changed=1;
end; $$;

revoke all on function public.cancel_personal_today_plan(uuid) from public,anon;
grant execute on function public.cancel_personal_today_plan(uuid) to authenticated;
