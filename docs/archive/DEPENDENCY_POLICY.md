# Dependency policy V1.2

- Direct runtime/dev dependencies are pinned to exact versions in `pubspec.yaml`.
- `pubspec.lock` must be committed for this application repository.
- Dependency updates happen deliberately, not during feature work.
- Before an update: `flutter pub outdated` and changelog/security review.
- After an update: `flutter analyze`, `flutter test`, `flutter build apk --debug`.
- Security-sensitive packages are reviewed immediately when a security advisory is published.
- Avoid adding packages for functionality already provided by Flutter or an existing dependency.
- `shared_preferences` is only for non-sensitive cache/preferences. Never store auth tokens, secrets or authorization state there.
- `connectivity_plus` is a connectivity hint only. Network operations must still handle request failures/timeouts.
