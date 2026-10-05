#!/usr/bin/env python3
import json
import plistlib
import sys
from pathlib import Path

if len(sys.argv) != 4:
    raise SystemExit('Usage: generate_firebase_options.py ANDROID_JSON IOS_PLIST OUTPUT_DART')

android_path, ios_path, out_path = map(Path, sys.argv[1:])
android = json.loads(android_path.read_text())
with ios_path.open('rb') as f:
    ios = plistlib.load(f)

project_info = android['project_info']
clients = android['client']
client = next(
    (
        c
        for c in clients
        if c.get('client_info', {})
        .get('android_client_info', {})
        .get('package_name') == 'com.example.food_app_mvp'
    ),
    clients[0],
)

content = '''import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

/// Firebase identifiers are supplied at build time. They are not secrets.
///
/// Android example:
/// flutter build apk \
///   --dart-define=FIREBASE_API_KEY=... \
///   --dart-define=FIREBASE_APP_ID=... \
///   --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
///   --dart-define=FIREBASE_PROJECT_ID=...
class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    iosBundleId: 'com.example.foodAppMvp',
  );

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Firebase Push ist für diese Plattform nicht konfiguriert.');
    }
  }
}
'''

# Keep reading both registered platform configs here. Their presence validates
# that Firebase is configured locally, while the generated Dart file remains
# free of project-specific identifiers and gets them only via dart-define.
_ = project_info
_ = client
_ = ios

out_path.write_text(content)
