drop policy if exists "foods readable by authenticated" on public.foods;
create policy "foods readable by authenticated" on public.foods
for select to authenticated
using (created_by is null or created_by = (select auth.uid()));

drop policy if exists "foods own insert" on public.foods;
create policy "foods own insert" on public.foods
for insert to authenticated
with check (created_by = (select auth.uid()));
