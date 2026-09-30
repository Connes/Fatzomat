-- The sender INSERT policy must not query recipe_suggestions itself.
-- PostgreSQL detects that as recursive RLS evaluation and rejects every insert.
drop policy if exists "recipe suggestions sender insert" on public.recipe_suggestions;
create policy "recipe suggestions sender insert"
on public.recipe_suggestions for insert to authenticated
with check (
  suggested_by = (select auth.uid())
  and suggested_by <> suggested_to
  and public.is_connection_member(connection_id)
  and public.is_connection_member(connection_id, suggested_to)
  and exists (
    select 1
    from public.recipes r
    where r.id = recipe_id
      and (
        r.created_by = (select auth.uid())
        or exists (
          select 1 from public.recipe_saves rs
          where rs.recipe_id = r.id and rs.user_id = (select auth.uid())
        )
        or exists (
          select 1 from public.shared_recipe_plans sp
          where sp.recipe_id = r.id and public.is_connection_member(sp.connection_id)
        )
      )
  )
);
