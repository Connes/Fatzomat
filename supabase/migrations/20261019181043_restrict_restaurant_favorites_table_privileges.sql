-- RLS does not apply to TRUNCATE. Remove all direct privileges first,
-- then grant only the CRUD operations required by the authenticated client.
revoke all on table public.restaurant_favorites from public, anon, authenticated;
grant select, insert, update, delete
  on table public.restaurant_favorites to authenticated;
