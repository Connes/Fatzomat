# Schmackofatz v1.13.0 – Restaurant Discovery Session Fix 16

## Fix

Fixes the regression-test compilation error introduced by the session-refresh
contract assertion in `test/regression/restaurant_discovery_test.dart`.

The assertion checks for the literal source text `$accessToken`. In Dart test
source, an unescaped `$accessToken` inside the assertion string is interpreted
as Dart string interpolation, where no runtime variable named `accessToken`
exists. The dollar sign is therefore escaped so the test checks the intended
source-code contract.

## Functional code

No restaurant-discovery runtime logic is changed in this fix. The previous
session refresh and explicit Authorization header remain intact:

- refresh Supabase session before the Edge Function call
- read the fresh `currentSession.accessToken`
- pass it as `Authorization: Bearer <token>`

## Verification

- Python source patch: passed
- ZIP integrity: passed
- Flutter analyze/tests: not executable in this build environment
