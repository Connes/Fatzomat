# Schmackofatz v1.13.0 - Push Delivery Fix 11

- Fixed regression test `Anonymer Start sendet keinen Benutzernamen an Supabase`.
- Kept the anonymous Supabase sign-in retry behavior unchanged while restoring the expected direct `auth.signInAnonymously();` call in `main.dart`.
- Firebase/FlutterFire configuration flow from Fix 10 remains unchanged.
