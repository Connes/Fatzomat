-- Fix recipe image uploads: the original storage policies accidentally
-- resolved foldername() against recipes.name instead of storage.objects.name.
-- Also align the live recipes schema with the client image update contract.

alter table public.recipes
  add column if not exists updated_at timestamptz;

update public.recipes
set updated_at = coalesce(updated_at, created_at)
where updated_at is null;

drop policy if exists "recipe images accessible with recipe" on storage.objects;
create policy "recipe images accessible with recipe"
on storage.objects for select to authenticated
using (
  bucket_id = 'recipe-images'
  and exists (
    select 1 from public.recipes r
    where r.id::text = (storage.foldername(storage.objects.name))[1]
      and (
        r.created_by = (select auth.uid())
        or exists (
          select 1
          from public.connection_members own_cm
          join public.connection_members recipe_cm
            on recipe_cm.connection_id = own_cm.connection_id
          where own_cm.user_id = (select auth.uid())
            and recipe_cm.user_id = r.created_by
        )
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

drop policy if exists "recipe images owner upload" on storage.objects;
create policy "recipe images owner upload"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'recipe-images'
  and exists (
    select 1 from public.recipes r
    where r.id::text = (storage.foldername(storage.objects.name))[1]
      and r.created_by = (select auth.uid())
  )
);

drop policy if exists "recipe images owner update" on storage.objects;
create policy "recipe images owner update"
on storage.objects for update to authenticated
using (
  bucket_id = 'recipe-images'
  and exists (
    select 1 from public.recipes r
    where r.id::text = (storage.foldername(storage.objects.name))[1]
      and r.created_by = (select auth.uid())
  )
)
with check (
  bucket_id = 'recipe-images'
  and exists (
    select 1 from public.recipes r
    where r.id::text = (storage.foldername(storage.objects.name))[1]
      and r.created_by = (select auth.uid())
  )
);

drop policy if exists "recipe images owner delete" on storage.objects;
create policy "recipe images owner delete"
on storage.objects for delete to authenticated
using (
  bucket_id = 'recipe-images'
  and exists (
    select 1 from public.recipes r
    where r.id::text = (storage.foldername(storage.objects.name))[1]
      and r.created_by = (select auth.uid())
  )
);
