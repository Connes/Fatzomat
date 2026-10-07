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

android_app_id = client['client_info']['mobilesdk_app_id']
android_api_key = client['api_key'][0]['current_key']
sender_id = str(project_info['project_number'])
ios_app_id = ios['GOOGLE_APP_ID']

if android_api_key != ios.get('API_KEY', android_api_key):
    raise SystemExit('Firebase Android/iOS API keys do not match the configured project.')

if str(project_info['project_id']) != 'schmackofatz-25cce':
    raise SystemExit(
        f"Unexpected Firebase project: {project_info['project_id']}. "
        "Refusing to generate configuration for a different project."
    )

content = '''import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

/// Firebase identifiers are supplied at build time. They are not secrets.
/// Platform-specific app IDs are required because Android and iOS are
/// registered as different Firebase applications.
class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID'),
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
        throw UnsupportedError(
          'Firebase Push ist für diese Plattform nicht konfiguriert.',
        );
    }
  }
}
'''

# The generated Dart file intentionally contains no project-specific values.
# Keep the registered identifiers in the local platform config files and pass
# them as dart-defines at run/build time.
_ = project_info
_ = client
_ = android_app_id
_ = android_api_key
_ = sender_id
_ = ios_app_id

out_path.write_text(content)
