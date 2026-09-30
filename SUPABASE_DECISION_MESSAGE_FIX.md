# Decision message / sharing fix

Both `Entscheide Du` and `Entscheidung teilen` create an `app_notifications` row.
The push trigger is asynchronous and must not be able to roll back that database
transaction when pg_net, Vault, or FCM delivery fails.

Migration `20260925200000_harden_push_notifications_webhook.sql` wraps the
push webhook call in an exception handler. The durable decision message is now
kept even if push delivery has a transient backend problem.
