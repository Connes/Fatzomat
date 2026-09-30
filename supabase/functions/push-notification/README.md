# Push notification bridge

This Edge Function receives an `app_notifications` INSERT from a Supabase Database Webhook and forwards it to Firebase Cloud Messaging.

Required Edge Function secrets:

- `FCM_SERVICE_ACCOUNT_JSON`: the Firebase service-account JSON, stored as one JSON string.
- `PUSH_WEBHOOK_SECRET`: optional shared secret if the webhook sends `x-push-webhook-secret`.

The app stores each device's FCM registration token in `public.push_devices`.

Create a Supabase Database Webhook for `public.app_notifications` on `INSERT` and target this function with POST. Supabase documents Database Webhooks as asynchronous HTTP triggers and specifically documents the push-notification pattern with an Edge Function. 
