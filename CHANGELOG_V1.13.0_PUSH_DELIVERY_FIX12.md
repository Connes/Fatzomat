# Schmackofatz v1.13.0 - Push Delivery Fix 12

- Firebase setup no longer depends exclusively on FlutterFire project listing.
- If FlutterFire times out while listing projects, setup falls back to the official Firebase CLI.
- The fallback retrieves the already registered Android and iOS Firebase app configs via `firebase apps:sdkconfig`.
- `lib/firebase_options.dart` is generated locally from those service configs.
- No new Firebase project is ever created automatically.
- Added `.firebaserc` with the existing project `schmackofatz-25cce`.
