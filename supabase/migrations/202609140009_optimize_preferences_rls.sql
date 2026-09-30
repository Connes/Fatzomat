alter policy "preferences own" on public.user_food_preferences
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));
