-- Harden recipe removal semantics.
-- A non-owner may only remove their own collection save.
-- Only the recipe owner may permanently delete the recipe, and active
-- personal/shared plans keep it alive to avoid cascading today's selection.

create or replace function public.remove_recipe_from_collection(p_recipe_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  owner_id uuid;
  deleted_recipe boolean := false;
begin
  if uid is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  select r.created_by
    into owner_id
    from public.recipes r
   where r.id = p_recipe_id
     and (
       r.created_by = uid
       or exists (
         select 1
           from public.recipe_saves rs
          where rs.recipe_id = r.id
            and rs.user_id = uid
       )
     )
   limit 1;

  if owner_id is null then
    raise exception 'Rezept ist nicht verfügbar.';
  end if;

  -- Always remove only the caller's collection membership first.
  delete from public.recipe_saves
   where recipe_id = p_recipe_id
     and user_id = uid;

  -- A saved copy belonging to another user must never be destroyed by
  -- someone who only removed their own save.
  if owner_id <> uid then
    return false;
  end if;

  -- Keep recipes referenced by an active shared or personal plan.
  if exists (
    select 1
      from public.shared_recipe_plans sp
     where sp.recipe_id = p_recipe_id
       and sp.status <> 'cancelled'
  ) or exists (
    select 1
      from public.personal_today_plans pp
     where pp.recipe_id = p_recipe_id
       and pp.status <> 'cancelled'
  ) then
    return false;
  end if;

  -- The owner can permanently delete only when nobody else still has it.
  if not exists (
    select 1
      from public.recipe_saves rs
     where rs.recipe_id = p_recipe_id
  ) then
    delete from public.recipes where id = p_recipe_id;
    deleted_recipe := true;
  end if;

  return deleted_recipe;
end;
$$;

revoke all on function public.remove_recipe_from_collection(uuid) from public, anon;
grant execute on function public.remove_recipe_from_collection(uuid) to authenticated;
