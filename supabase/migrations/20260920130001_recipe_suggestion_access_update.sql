-- Follow-up hardening: a user may suggest any recipe they can explicitly access.
drop policy if exists "recipe suggestions sender insert" on public.recipe_suggestions;
create policy "recipe suggestions sender insert"
on public.recipe_suggestions for insert to authenticated
with check (
  suggested_by = (select auth.uid())
  and suggested_by <> suggested_to
  and public.is_connection_member(connection_id)
  and public.is_connection_member(connection_id, suggested_to)
  and exists (
    select 1 from public.recipes r
    where r.id = recipe_id
      and (
        r.created_by = (select auth.uid())
        or exists (select 1 from public.recipe_saves rs where rs.recipe_id = r.id and rs.user_id = (select auth.uid()))
        or exists (select 1 from public.shared_recipe_plans sp where sp.recipe_id = r.id and public.is_connection_member(sp.connection_id))
        or exists (select 1 from public.recipe_suggestions old_rs where old_rs.recipe_id = r.id and old_rs.suggested_to = (select auth.uid()) and old_rs.status in ('pending','accepted') and public.is_connection_member(old_rs.connection_id))
      )
  )
);

create or replace function public.create_recipe_suggestion(p_recipe_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  cid uuid;
  recipient uuid;
  row public.recipe_suggestions;
begin
  if uid is null then raise exception 'Keine Supabase-Sitzung vorhanden.'; end if;
  select cm.connection_id into cid from public.connection_members cm where cm.user_id = uid limit 1;
  if cid is null then raise exception 'Keine Verbindung zu einer zweiten Person vorhanden.'; end if;
  select cm.user_id into recipient from public.connection_members cm where cm.connection_id = cid and cm.user_id <> uid limit 1;
  if recipient is null then raise exception 'Keine verbundene Person vorhanden.'; end if;
  if not exists (
    select 1 from public.recipes r
    where r.id = p_recipe_id
      and (
        r.created_by = uid
        or exists (select 1 from public.recipe_saves rs where rs.recipe_id = r.id and rs.user_id = uid)
        or exists (select 1 from public.shared_recipe_plans sp where sp.recipe_id = r.id and public.is_connection_member(sp.connection_id))
        or exists (select 1 from public.recipe_suggestions old_rs where old_rs.recipe_id = r.id and old_rs.suggested_to = uid and old_rs.status in ('pending','accepted') and public.is_connection_member(old_rs.connection_id))
      )
  ) then
    raise exception 'Das Rezept ist für dich nicht freigegeben.';
  end if;
  select * into row from public.recipe_suggestions rs
    where rs.connection_id = cid and rs.recipe_id = p_recipe_id and rs.suggested_by = uid and rs.suggested_to = recipient and rs.status = 'pending'
    limit 1;
  if row.id is null then
    insert into public.recipe_suggestions(connection_id, recipe_id, suggested_by, suggested_to)
    values (cid, p_recipe_id, uid, recipient)
    returning * into row;
  end if;
  return jsonb_build_object('id', row.id, 'connection_id', row.connection_id, 'recipe_id', row.recipe_id, 'suggested_by', row.suggested_by, 'suggested_to', row.suggested_to, 'status', row.status, 'created_at', row.created_at, 'responded_at', row.responded_at);
end;
$$;

revoke all on function public.create_recipe_suggestion(uuid) from public, anon;
grant execute on function public.create_recipe_suggestion(uuid) to authenticated;
