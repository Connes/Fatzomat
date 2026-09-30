-- Manual recipe images: private Supabase Storage with access tied to recipe access.
alter table public.recipes
  add column if not exists image_path text;

drop policy if exists "recipe images owner upload" on storage.objects;
drop policy if exists "recipe images accessible with recipe" on storage.objects;
drop policy if exists "recipe images owner update" on storage.objects;
drop policy if exists "recipe images owner delete" on storage.objects;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'recipe-images',
  'recipe-images',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update
set public = false,
    file_size_limit = 10485760,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']::text[];

create policy "recipe images owner upload"
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'recipe-images'
  and exists (
    select 1
    from public.recipes r
    where r.id::text = (storage.foldername(name))[1]
      and r.created_by = (select auth.uid())
  )
);

create policy "recipe images accessible with recipe"
on storage.objects
for select to authenticated
using (
  bucket_id = 'recipe-images'
  and exists (
    select 1
    from public.recipes r
    where r.id::text = (storage.foldername(name))[1]
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
          select 1
          from public.recipe_saves rs
          where rs.recipe_id = r.id
            and rs.user_id = (select auth.uid())
        )
        or exists (
          select 1
          from public.shared_recipe_plans sp
          where sp.recipe_id = r.id
            and public.is_connection_member(sp.connection_id)
        )
      )
  )
);

create policy "recipe images owner update"
on storage.objects
for update to authenticated
using (
  bucket_id = 'recipe-images'
  and exists (
    select 1
    from public.recipes r
    where r.id::text = (storage.foldername(name))[1]
      and r.created_by = (select auth.uid())
  )
)
with check (bucket_id = 'recipe-images');

create policy "recipe images owner delete"
on storage.objects
for delete to authenticated
using (
  bucket_id = 'recipe-images'
  and exists (
    select 1
    from public.recipes r
    where r.id::text = (storage.foldername(name))[1]
      and r.created_by = (select auth.uid())
  )
);
