-- V89: Accepting a shared recipe decision creates the common shopping list.
-- The list belongs to the connection's shared_recipe_plan and is visible to both partners.

alter table public.decision_shares
  add column if not exists shared_recipe_plan_id uuid
    references public.shared_recipe_plans(id) on delete set null;

create index if not exists idx_decision_shares_shared_recipe_plan
  on public.decision_shares(shared_recipe_plan_id);

create or replace function public.accept_decision_share(p_share_id uuid)
returns jsonb
language plpgsql security definer set search_path=public,pg_temp
as $$
declare
  uid uuid:=auth.uid();
  share_row public.decision_shares;
  source_recipe public.recipes;
  copied_recipe_id uuid;
  personal_plan_id uuid;
  shared_plan_id uuid;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;

  select * into share_row
  from public.decision_shares
  where id=p_share_id and recipient_id=uid and public.is_connection_member(connection_id)
  for update;

  if share_row.id is null then raise exception 'Die geteilte Entscheidung ist nicht mehr verfügbar.'; end if;
  if share_row.message_type<>'share' then raise exception 'Diese Nachricht enthält keine übernehmbare Entscheidung.'; end if;
  if share_row.cancelled_at is not null then raise exception 'Diese gemeinsame Entscheidung wurde bereits entfernt.'; end if;
  if share_row.plan_date<>current_date then raise exception 'Die geteilte Entscheidung gilt nicht mehr für heute.'; end if;

  if share_row.accepted_at is not null and share_row.accepted_plan_id is not null then
    return jsonb_build_object(
      'share_id',share_row.id,
      'plan_id',share_row.accepted_plan_id,
      'decision_type',share_row.decision_type,
      'recipe_id',share_row.accepted_recipe_id,
      'shared_recipe_plan_id',share_row.shared_recipe_plan_id
    );
  end if;

  if share_row.decision_type='recipe' then
    if share_row.recipe_id is null then raise exception 'Das geteilte Rezept ist nicht mehr verfügbar.'; end if;

    copied_recipe_id:=share_row.accepted_recipe_id;
    if copied_recipe_id is null then
      select * into source_recipe
      from public.recipes
      where id=share_row.recipe_id and created_by=share_row.sender_id
      for share;

      if source_recipe.id is null then raise exception 'Das geteilte Rezept ist nicht mehr verfügbar.'; end if;

      insert into public.recipes(
        created_by,name,description,servings,prep_time_minutes,cook_time_minutes,
        difficulty,instructions,image_url
      )
      values(
        uid,source_recipe.name,source_recipe.description,source_recipe.servings,
        source_recipe.prep_time_minutes,source_recipe.cook_time_minutes,
        source_recipe.difficulty,source_recipe.instructions,source_recipe.image_url
      )
      returning id into copied_recipe_id;

      insert into public.recipe_ingredients(
        recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative
      )
      select copied_recipe_id,food_id,name,quantity,unit,is_user_selected,is_additional,is_qualitative
      from public.recipe_ingredients
      where recipe_id=share_row.recipe_id;

      insert into public.recipe_saves(recipe_id,user_id)
      values(copied_recipe_id,uid)
      on conflict(recipe_id,user_id) do nothing;
    else
      select * into source_recipe
      from public.recipes
      where id=share_row.recipe_id;
    end if;

    personal_plan_id:=public.set_personal_today_plan(copied_recipe_id,share_row.servings);

    select id into shared_plan_id
    from public.shared_recipe_plans
    where connection_id=share_row.connection_id
      and plan_date=current_date
      and status<>'cancelled'
    order by created_at desc
    limit 1;

    if shared_plan_id is null then
      insert into public.shared_recipe_plans(
        connection_id,recipe_id,shared_by,plan_date,status,servings
      )
      values(
        share_row.connection_id,
        share_row.recipe_id,
        share_row.sender_id,
        current_date,
        'planned',
        share_row.servings
      )
      returning id into shared_plan_id;

      insert into public.shopping_items(
        shared_recipe_plan_id,food_id,name,quantity,unit,source
      )
      select
        shared_plan_id,
        ri.food_id,
        ri.name,
        round((ri.quantity * share_row.servings::numeric / greatest(coalesce(source_recipe.servings,1),1))::numeric,2),
        ri.unit,
        'recipe'
      from public.recipe_ingredients ri
      where ri.recipe_id=share_row.recipe_id;
    end if;

    update public.decision_shares
    set accepted_at=now(),
        accepted_plan_id=personal_plan_id,
        shared_recipe_plan_id=shared_plan_id
    where id=share_row.id;

    return jsonb_build_object(
      'share_id',share_row.id,
      'plan_id',personal_plan_id,
      'decision_type',share_row.decision_type,
      'recipe_id',copied_recipe_id,
      'shared_recipe_plan_id',shared_plan_id
    );
  elsif share_row.decision_type in ('order','dine_out','surprise') then
    if nullif(btrim(share_row.decision_value),'') is null then
      raise exception 'Die geteilte Entscheidung ist nicht mehr vollständig verfügbar.';
    end if;

    personal_plan_id:=public.set_personal_today_decision(
      share_row.decision_type,share_row.decision_value
    );

    update public.decision_shares
    set accepted_at=now(),accepted_plan_id=personal_plan_id
    where id=share_row.id;

    return jsonb_build_object(
      'share_id',share_row.id,
      'plan_id',personal_plan_id,
      'decision_type',share_row.decision_type,
      'recipe_id',null,
      'shared_recipe_plan_id',null
    );
  else
    raise exception 'Ungültige geteilte Entscheidung.';
  end if;
end;
$$;

revoke all on function public.accept_decision_share(uuid) from public,anon;
grant execute on function public.accept_decision_share(uuid) to authenticated;

create or replace function public.cancel_personal_today_plan(p_plan_id uuid)
returns boolean
language plpgsql security definer set search_path=public,pg_temp
as $$
declare
  uid uuid:=auth.uid();
  changed integer:=0;
  rid uuid;
  partner_plan_id uuid;
  shared_plan_id uuid;
  share_row public.decision_shares;
  partner uuid;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;

  select recipe_id into rid
  from public.personal_today_plans
  where id=p_plan_id and user_id=uid and plan_date=current_date and status<>'cancelled';
  if not found then return false; end if;

  select * into share_row
  from public.decision_shares
  where message_type='share'
    and cancelled_at is null
    and (source_plan_id=p_plan_id or accepted_plan_id=p_plan_id)
  order by created_at desc
  limit 1
  for update;

  if share_row.id is not null then
    partner:=case when share_row.sender_id=uid then share_row.recipient_id else share_row.sender_id end;
    partner_plan_id:=case when share_row.sender_id=uid then share_row.accepted_plan_id else share_row.source_plan_id end;
    shared_plan_id:=share_row.shared_recipe_plan_id;

    update public.decision_shares
    set cancelled_at=now(),cancelled_by=uid
    where id=share_row.id;

    if shared_plan_id is not null then
      delete from public.shared_recipe_plans where id=shared_plan_id;
    end if;

    if partner_plan_id is not null then
      delete from public.shopping_items where personal_today_plan_id=partner_plan_id;
      update public.personal_today_plans
      set status='cancelled',updated_at=now()
      where id=partner_plan_id and user_id=partner and plan_date=current_date and status<>'cancelled';

      insert into public.app_notifications(user_id,type,title,body,decision_share_id,shared_recipe_plan_id)
      values(
        partner,
        'decision_shared_deleted',
        'Gemeinsame Entscheidung entfernt',
        'Die gemeinsame Tagesentscheidung wurde von deiner verbundenen Person entfernt.',
        share_row.id,
        null
      );
    end if;
  end if;

  delete from public.shopping_items where personal_today_plan_id=p_plan_id;
  update public.personal_today_plans
  set status='cancelled',updated_at=now()
  where id=p_plan_id and user_id=uid and plan_date=current_date and status<>'cancelled';
  get diagnostics changed=row_count;

  if changed=1 then
    insert into public.personal_decision_history(user_id,plan_id,recipe_id,action,source)
    values(uid,p_plan_id,rid,'cancelled','today');
  end if;

  return changed=1;
end;
$$;

revoke all on function public.cancel_personal_today_plan(uuid) from public,anon;
grant execute on function public.cancel_personal_today_plan(uuid) to authenticated;
