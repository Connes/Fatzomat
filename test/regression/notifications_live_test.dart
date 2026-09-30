import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V84 retains live notifications while extending Home decision sync', () {
    final profile = File('lib/features/settings/settings_page.dart').readAsStringSync();
    final page = File('lib/features/settings/notifications_page.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('version: 1.13.31+243'));
    expect(profile, contains('settings-notifications-'));
    expect(profile, contains('PostgresChangeEvent.all'));
    expect(profile, contains('unreadNotifications'));
    expect(profile, contains('removeChannel(notificationsChannel!)'));
    expect(page, contains("item.sharedRecipePlanId != null || item.type == 'shared_recipe'"));
    expect(page, contains('const TodayPage()'));
    expect(page, contains("Badge(label: Text('\$unread'))"));
  });
}
