-- Register an FCM token atomically for the currently authenticated user.
-- This avoids RLS failures when Android rotates/reuses a token after an
-- anonymous Supabase identity changes on the same physical device.
create or replace function public.register_push_device(
  p_device_token text,
  p_platform text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if btrim(coalesce(p_device_token, '')) = '' then
    raise exception 'Push device token is required';
  end if;

  if p_platform not in ('android', 'ios', 'other') then
    raise exception 'Invalid push platform';
  end if;

  insert into public.push_devices (user_id, device_token, platform, updated_at)
  values (auth.uid(), btrim(p_device_token), p_platform, now())
  on conflict (device_token) do update
    set user_id = excluded.user_id,
        platform = excluded.platform,
        updated_at = now();
end;
$$;

revoke execute on function public.register_push_device(text, text) from public;
revoke execute on function public.register_push_device(text, text) from anon;
grant execute on function public.register_push_device(text, text) to authenticated;
