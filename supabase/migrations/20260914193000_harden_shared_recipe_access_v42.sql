-- v42: shared recipe access, realtime collection sync, and safe recipe removal.

-- Ingredients must be readable by both connected users when the recipe is in
-- either user's collection or is planned for the connection.
drop policy if exists "recipe ingredients via own recipe" on public.recipe_ingredients;
drop policy if exists "recipe ingredients owner insert" on public.recipe_ingredients;
drop policy if exists "recipe ingredients readable for collection" on public.recipe_ingredients;

create policy "recipe ingredients readable for collection"
on public.recipe_ingredients for select to authenticated
using (
  exists (
    select 1
    from public.recipes r
    where r.id = recipe_ingredients.recipe_id
      and (
        r.created_by = (select auth.uid())
        or exists (
          select 1 from public.recipe_saves rs
          where rs.recipe_id = r.id
            and rs.user_id = (select auth.uid())
        )
        or exists (
          select 1 from public.recipe_saves rs
          where rs.recipe_id = r.id
            and public.is_connection_member(public.current_connection_id(), rs.user_id)
        )
        or exists (
          select 1 from public.shared_recipe_plans sp
          where sp.recipe_id = r.id
            and public.is_connection_member(sp.connection_id)
        )
      )
  )
);

create policy "recipe ingredients owner insert"
on public.recipe_ingredients for insert to authenticated
with check (
  exists (
    select 1 from public.recipes r
    where r.id = recipe_ingredients.recipe_id
      and r.created_by = (select auth.uid())
  )
);

create policy "recipe ingredients owner update"
on public.recipe_ingredients for update to authenticated
using (
  exists (
    select 1 from public.recipes r
    where r.id = recipe_ingredients.recipe_id
      and r.created_by = (select auth.uid())
  )
)
with check (
  exists (
    select 1 from public.recipes r
    where r.id = recipe_ingredients.recipe_id
      and r.created_by = (select auth.uid())
  )
);

create policy "recipe ingredients owner delete"
on public.recipe_ingredients for delete to authenticated
using (
  exists (
    select 1 from public.recipes r
    where r.id = recipe_ingredients.recipe_id
      and r.created_by = (select auth.uid())
  )
);

-- Realtime collection updates allow the second device to see a save immediately.
alter publication supabase_realtime add table public.recipe_saves;

-- Remove a recipe from the current user's collection safely. If the current
-- user owns the recipe, their save is removed first. The underlying recipe is
-- deleted only when nobody else has saved it and it is not used by an active
-- shared plan.
create or replace function public.remove_recipe_from_collection(p_recipe_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  owner_id uuid;
  deleted_recipe boolean := false;
begin
  if auth.uid() is null then
    raise exception 'Keine Supabase-Sitzung vorhanden.';
  end if;

  select r.created_by into owner_id
  from public.recipes r
  where r.id = p_recipe_id
    and (
      r.created_by = auth.uid()
      or exists (
        select 1 from public.recipe_saves rs
        where rs.recipe_id = r.id and rs.user_id = auth.uid()
      )
    )
  limit 1;

  if owner_id is null then
    raise exception 'Rezept ist nicht verfügbar.';
  end if;

  delete from public.recipe_saves
  where recipe_id = p_recipe_id and user_id = auth.uid();

  if owner_id = auth.uid()
     and not exists (
       select 1 from public.recipe_saves rs
       where rs.recipe_id = p_recipe_id
     )
     and not exists (
       select 1 from public.shared_recipe_plans sp
       where sp.recipe_id = p_recipe_id
         and sp.status <> 'cancelled'
     ) then
    delete from public.recipes where id = p_recipe_id;
    deleted_recipe := true;
  end if;

  return deleted_recipe;
end;
$$;

revoke execute on function public.remove_recipe_from_collection(uuid) from public, anon;
grant execute on function public.remove_recipe_from_collection(uuid) to authenticated;
