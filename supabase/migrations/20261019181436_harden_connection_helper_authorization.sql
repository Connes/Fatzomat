-- Limit SECURITY DEFINER membership helpers to callers who belong to the
-- requested connection. The public RPC surface must not permit cross-connection
-- membership enumeration or display-name lookup.
create or replace function public.connection_member_display_name(
  p_connection_id uuid,
  p_user_id uuid
)
returns text
language sql
stable
security definer
set search_path = pg_catalog, pg_temp
as $function$
  select coalesce(
    nullif(btrim(cm.display_name), ''),
    nullif(btrim(p.display_name), ''),
    'Deine verbundene Person'
  )
  from public.connection_members cm
  left join public.profiles p on p.id = cm.user_id
  where cm.connection_id = p_connection_id
    and cm.user_id = p_user_id
    and exists (
      select 1
      from public.connection_members caller
      where caller.connection_id = p_connection_id
        and caller.user_id = auth.uid()
    )
  limit 1;
$function$;

create or replace function public.is_connection_member(
  p_connection_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, pg_temp
as $function$
  select exists (
    select 1
    from public.connection_members target
    where target.connection_id = p_connection_id
      and target.user_id = p_user_id
      and exists (
        select 1
        from public.connection_members caller
        where caller.connection_id = p_connection_id
          and caller.user_id = auth.uid()
      )
  );
$function$;
