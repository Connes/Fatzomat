import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Push notification infrastructure is wired', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();
    final app = File('lib/core/app.dart').readAsStringSync();
    final service = File('lib/core/push_notification_service.dart').readAsStringSync();
    final migration = File('supabase/migrations/20260925153000_push_notifications.sql').readAsStringSync();
    final function = File('supabase/functions/push-notification/index.ts').readAsStringSync();
    final common = File('scripts/common.sh').readAsStringSync();
    final runApp = File('scripts/run_app.sh').readAsStringSync();
    final firebaseOptions = File('lib/firebase_options.dart').readAsStringSync();
    final pushRepo = File('lib/data/repositories/push_device_repository.dart').readAsStringSync();
    final pushRpc = File('supabase/migrations/20260927070000_register_push_device_rpc.sql').readAsStringSync();
    final androidManifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(pubspec, contains('firebase_core:'));
    expect(pubspec, contains('firebase_messaging:'));
    expect(pubspec, contains('flutter_local_notifications:'));
    expect(main, contains('Firebase.initializeApp'));
    expect(main, contains('PushNotificationService.instance.initialize'));
    expect(main, contains('_signInAnonymouslyWithRetry'));
    expect(main, contains('Erneut versuchen'));
    expect(androidManifest, contains('android.permission.INTERNET'));
    expect(app, contains('navigatorKey: appNavigatorKey'));
    expect(service, contains('FirebaseMessaging.onMessageOpenedApp'));
    expect(service, contains('getInitialMessage'));
    expect(service, contains('NotificationsPage(initialNotificationId: id)'));
    expect(service, contains('DecisionSharePage(share: share)'));
    expect(service, contains("decision_share_id"));
    expect(service, contains("_pendingDecisionShareId"));
    expect(function, contains("decision_share_id: String(notification.decision_share_id ?? '')"));
    expect(function, contains("recipe_id: String(notification.recipe_id ?? '')"));
    expect(migration, contains('create table if not exists public.push_devices'));
    expect(function, contains('fcm.googleapis.com/v1/projects'));
    expect(common, contains('flutterfire configure'));
    expect(File('scripts/setup.sh').readAsStringSync(), contains('configure_firebase_if_needed'));
    expect(common, contains('Found 0 Firebase projects'));
    expect(common, contains('KEIN neues Firebase-Projekt'));
    expect(common, contains('firebase projects:list --project=schmackofatz-25cce'));
    expect(common, contains("printf 'n\\n' | flutterfire configure"));
    expect(runApp, contains('configure_firebase_if_needed'));
    expect(firebaseOptions, contains('class DefaultFirebaseOptions'));
    expect(firebaseOptions, contains("projectId: String.fromEnvironment('FIREBASE_PROJECT_ID')"));
    expect(firebaseOptions, contains("apiKey: String.fromEnvironment('FIREBASE_API_KEY')"));
    expect(pushRepo, contains("register_push_device"));
    expect(pushRpc, contains('create or replace function public.register_push_device'));
  });
}
