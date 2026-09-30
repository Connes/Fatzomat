drop policy if exists "profiles own" on public.profiles;
create policy "profiles own" on public.profiles
for all to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));
