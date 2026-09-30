-- V86: Accept a shared personal decision without crossing RLS boundaries.
--
-- A shared recipe is owned by the sender. The recipient must not directly
-- insert that foreign recipe into recipe_saves. This RPC validates the share,
-- creates an independent personal copy of a recipe, and applies the copy to
-- the recipient's personal Today plan in one transaction. Non-recipe decisions
-- are applied directly through the existing personal decision RPC.

alter table public.decision_shares
  add column if not exists accepted_at timestamptz,
  add column if not exists accepted_recipe_id uuid references public.recipes(id) on delete set null;

create index if not exists idx_decision_shares_accepted_recipe
  on public.decision_shares(accepted_recipe_id)
  where accepted_recipe_id is not null;

create or replace function public.accept_decision_share(p_share_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  share_row public.decision_shares;
  source_recipe public.recipes;
  copied_recipe_id uuid;
  plan_id uuid;
begin
  if uid is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  if p_share_id is null then
    raise exception 'Keine Entscheidungs-ID vorhanden.';
  end if;

  select *
    into share_row
  from public.decision_shares
  where id = p_share_id
    and recipient_id = uid
    and public.is_connection_member(connection_id)
  for update;

  if share_row.id is null then
    raise exception 'Die geteilte Entscheidung ist nicht mehr verfügbar.';
  end if;

  if share_row.message_type <> 'share' then
    raise exception 'Diese Nachricht enthält keine übernehmbare Entscheidung.';
  end if;

  if share_row.plan_date <> current_date then
    raise exception 'Die geteilte Entscheidung gilt nicht mehr für heute.';
  end if;

  if share_row.decision_type = 'recipe' then
    if share_row.recipe_id is null then
      raise exception 'Das geteilte Rezept ist nicht mehr verfügbar.';
    end if;

    copied_recipe_id := share_row.accepted_recipe_id;

    if copied_recipe_id is null then
      select *
        into source_recipe
      from public.recipes
      where id = share_row.recipe_id
        and created_by = share_row.sender_id
      for share;

      if source_recipe.id is null then
        raise exception 'Das geteilte Rezept ist nicht mehr verfügbar.';
      end if;

      insert into public.recipes(
        created_by, name, description, servings, prep_time_minutes,
        cook_time_minutes, difficulty, instructions, image_url
      )
      values (
        uid, source_recipe.name, source_recipe.description, source_recipe.servings,
        source_recipe.prep_time_minutes, source_recipe.cook_time_minutes,
        source_recipe.difficulty, source_recipe.instructions, source_recipe.image_url
      )
      returning id into copied_recipe_id;

      insert into public.recipe_ingredients(
        recipe_id, food_id, name, quantity, unit,
        is_user_selected, is_additional, is_qualitative
      )
      select
        copied_recipe_id, food_id, name, quantity, unit,
        is_user_selected, is_additional, is_qualitative
      from public.recipe_ingredients
      where recipe_id = share_row.recipe_id;

      insert into public.recipe_saves(recipe_id, user_id)
      values (copied_recipe_id, uid)
      on conflict (recipe_id, user_id) do nothing;

      update public.decision_shares
      set accepted_recipe_id = copied_recipe_id,
          accepted_at = now()
      where id = share_row.id;
    else
      update public.decision_shares
      set accepted_at = now()
      where id = share_row.id;
    end if;

    plan_id := public.set_personal_today_plan(copied_recipe_id, share_row.servings);
  elsif share_row.decision_type in ('order', 'dine_out', 'surprise') then
    if nullif(btrim(share_row.decision_value), '') is null then
      raise exception 'Die geteilte Entscheidung ist nicht mehr vollständig verfügbar.';
    end if;

    plan_id := public.set_personal_today_decision(
      share_row.decision_type,
      share_row.decision_value
    );

    update public.decision_shares
    set accepted_at = now()
    where id = share_row.id;
  else
    raise exception 'Ungültige geteilte Entscheidung.';
  end if;

  return jsonb_build_object(
    'share_id', share_row.id,
    'plan_id', plan_id,
    'decision_type', share_row.decision_type,
    'recipe_id', copied_recipe_id
  );
end;
$$;

revoke all on function public.accept_decision_share(uuid) from public, anon;
grant execute on function public.accept_decision_share(uuid) to authenticated;
