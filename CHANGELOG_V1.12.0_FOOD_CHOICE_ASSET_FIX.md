# V1.12.0 - Food-Choice Asset Runtime Fix

- Fixed missing Food-Choice images at runtime.
- Explicitly registered `cooking`, `delivery`, and `restaurant` asset directories in `pubspec.yaml`.
- Added a regression test that loads all mapped Food-Choice assets through `rootBundle`.
- Kept the existing Surprise asset unchanged.
- No application business logic changed.
