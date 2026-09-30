# V1.13.0 – Restaurant Discovery Session Fix 15

## Fehler

„Wir bestellen“ konnte trotz vorhandener persönlicher Supabase-Sitzung mit „Die persönliche Sitzung ist nicht gültig“ abbrechen.

## Ursache

Nach einem Android-Resume bzw. dem Standort-Berechtigungsfluss konnte `functions.invoke()` in einem ungünstigen Timing weiterhin einen alten bzw. nicht explizit aktualisierten Access-Token verwenden. Die Edge Function `restaurant-discovery` erwartet für `withSupabase({ auth: 'user' })` den Benutzer-JWT im `Authorization`-Header.

## Fix

- Supabase-Sitzung unmittelbar vor der Suche aktualisieren.
- Den frisch aus `currentSession` gelesenen Access-Token explizit als `Authorization: Bearer ...` an die Edge Function übergeben.
- Eine Suche ohne gültigen Access-Token wird klar als abgelaufene Sitzung gemeldet.
- Bestehende 20-km-, Liefer- und Ergebnislimits bleiben unverändert.
