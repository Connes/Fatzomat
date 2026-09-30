# v1.13.0 - Restaurant discovery session refresh

## Fix
The restaurant discovery flow now refreshes the Supabase session immediately before invoking the authenticated `restaurant-discovery` Edge Function.

This prevents a stale/expired access token from producing the generic:

> Die persönliche Sitzung ist nicht gültig. Bitte starte Schmackofatz neu.

error after the Android location permission flow resumes the app.

The existing location and restaurant search behavior remains unchanged.
