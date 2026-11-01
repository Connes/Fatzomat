import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS app and Firebase use the established cross-platform application id', () {
    const applicationId = 'com.example.food_app_mvp';

    final android = File('android/app/build.gradle.kts').readAsStringSync();
    final iosProject = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final firebaseOptions = File('lib/firebase_options.dart').readAsStringSync();

    expect(android, contains('applicationId = "$applicationId"'));
    expect(iosProject, contains('PRODUCT_BUNDLE_IDENTIFIER = $applicationId;'));
    expect(iosProject, isNot(contains('com.example.foodAppMvp')));
    expect(firebaseOptions, contains("iosBundleId: '$applicationId'"));

    final setupScript = File('scripts/common.sh').readAsStringSync();
    expect(setupScript, contains('--ios-bundle-id=$applicationId'));
    expect(setupScript, isNot(contains('--ios-bundle-id=com.example.foodAppMvp')));
  });
}
