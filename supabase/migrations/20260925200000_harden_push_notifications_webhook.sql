-- V85.2: Push delivery must never make the collaboration message transaction fail.
-- The database notification is the durable in-app event. Push delivery is
-- asynchronous and best-effort, so failures in pg_net/Vault/FCM must not roll
-- back decision_shares or app_notifications.

create or replace function public.push_notifications_webhook()
returns trigger
language plpgsql
security definer
set search_path = public, vault, net
as $$
declare
  anon_key text;
begin
  begin
    select decrypted_secret
      into anon_key
    from vault.decrypted_secrets
    where name = 'push_webhook_anon_key'
    limit 1;

    if anon_key is null or btrim(anon_key) = '' then
      raise warning 'push_notifications_webhook: push_webhook_anon_key is missing';
      return new;
    end if;

    perform net.http_post(
      url := 'https://oidxezjdwqktpxuypbfb.supabase.co/functions/v1/push-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || anon_key
      ),
      body := jsonb_build_object(
        'type', 'INSERT',
        'table', 'app_notifications',
        'schema', 'public',
        'record', to_jsonb(new),
        'old_record', null
      ),
      timeout_milliseconds := 5000
    );
  exception when others then
    raise warning 'push_notifications_webhook failed: %', sqlerrm;
  end;

  return new;
end;
$$;

revoke execute on function public.push_notifications_webhook() from public;
revoke execute on function public.push_notifications_webhook() from anon;
revoke execute on function public.push_notifications_webhook() from authenticated;
