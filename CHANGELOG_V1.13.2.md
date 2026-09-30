# Schmackofatz v1.13.2+214

- `friendlyError`: fallback for subclasses of non-sealed `AppException` added to switch expression.
- Recipe import preview: removed invalid `editing` reference; this screen only saves imported recipes.
- Updated pubspec version and matching test expectations where present.

Validation: source-level checks and ZIP integrity only. Run `./setup.sh`, `flutter analyze`, and `flutter test` locally.
