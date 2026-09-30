# Settings hint removed

The informational text between the `Backup erstellen` and `Benachrichtigungen` cards was removed from `lib/features/settings/settings_page.dart`.

No replacement text was added. The normal 14px card spacing remains, and the existing cards, actions, navigation, and backend logic were not changed.

A regression assertion was added to `test/regression/settings_structure_test.dart` to ensure the removed hint does not return.

`flutter analyze` could not be run in this execution environment because Flutter is not installed/available here.
