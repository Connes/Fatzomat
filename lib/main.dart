import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';

import 'core/app.dart';
import 'core/auth_session_service.dart';
import 'core/config.dart';
import 'core/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.isValid) {
    runApp(const ConfigurationErrorApp());
    return;
  }

  const url = AppConfig.supabaseUrl;
  const publishableKey = AppConfig.supabasePublishableKey;

  bool firebaseReady = false;
  try {
    final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
    final configured = firebaseOptions.apiKey.isNotEmpty &&
        firebaseOptions.appId.isNotEmpty &&
        firebaseOptions.messagingSenderId.isNotEmpty &&
        firebaseOptions.projectId.isNotEmpty;
    if (configured) {
      await Firebase.initializeApp(options: firebaseOptions);
      firebaseReady = true;
    }
  } catch (_) {
    // Push is optional until Firebase identifiers are supplied for the build.
  }

  await Supabase.initialize(
    url: url,
    publishableKey: publishableKey,
  );

  // The app intentionally has no visible login screen. Each installation
  // receives a persistent anonymous Supabase identity so each user's recipes
  // and food preferences remain protected by Supabase RLS.
  try {
    await AuthSessionService.ensureValidSession(client: Supabase.instance.client);
  } on AuthException catch (e) {
    runApp(AnonymousAuthErrorApp(
      code: e.code ?? 'unknown',
      message: e.message,
      onRetry: _restartAnonymousAuth,
    ));
    return;
  } on TimeoutException catch (e) {
    runApp(AnonymousAuthErrorApp(
      code: 'network_timeout',
      message: e.message ?? 'Supabase war nicht erreichbar.',
      onRetry: _restartAnonymousAuth,
    ));
    return;
  } catch (e) {
    final text = e.toString();
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('ClientException')) {
      runApp(AnonymousAuthErrorApp(
        code: 'network_error',
        message: text,
        onRetry: _restartAnonymousAuth,
      ));
      return;
    }
    rethrow;
  }

  runApp(const FoodApp());

  if (firebaseReady) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PushNotificationService.instance.initialize();
      PushNotificationService.instance.attachNavigator();
    });
  }
}


Future<void> _signInAnonymouslyWithRetry(Future<dynamic> Function() signIn) async {
  Object? lastError;
  for (var attempt = 1; attempt <= 3; attempt++) {
    try {
      await signIn().timeout(const Duration(seconds: 15));
      return;
    } catch (error) {
      lastError = error;
      if (attempt < 3) {
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }
  }
  if (lastError is AuthException) {
    throw lastError;
  }
  throw lastError ?? StateError('Anonymous sign-in failed');
}

Future<void> _restartAnonymousAuth() async {
  try {
    await _signInAnonymouslyWithRetry(() async {
      await Supabase.instance.client.auth.signInAnonymously();
    });
    runApp(const FoodApp());
    final firebaseApp = Firebase.apps.isNotEmpty;
    if (firebaseApp) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await PushNotificationService.instance.initialize();
        PushNotificationService.instance.attachNavigator();
      });
    }
  } catch (error) {
    final message = error.toString();
    runApp(AnonymousAuthErrorApp(
      code: message.contains('TimeoutException') ? 'network_timeout' : 'network_error',
      message: message,
      onRetry: _restartAnonymousAuth,
    ));
  }
}

class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Die Supabase-Konfiguration fehlt. Starte die App mit den vorgesehenen --dart-define Parametern.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class AnonymousAuthErrorApp extends StatelessWidget {
  final String code;
  final String message;
  final VoidCallback onRetry;

  const AnonymousAuthErrorApp({
    super.key,
    required this.code,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final anonymousDisabled = code == 'anonymous_provider_disabled';
    final body = anonymousDisabled
        ? 'Die anonyme Anmeldung ist in Supabase deaktiviert.\n\n'
            'Öffne Supabase → Authentication → Sign In / Providers → Anonymous '
            'und aktiviere „Allow anonymous sign-ins“. Danach Schmackofatz neu starten.'
        : 'Die Anmeldung konnte nicht gestartet werden.\n\n'
            'Bitte prüfe deine Verbindung und starte Schmackofatz erneut.';

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Schmackofatz')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(body, textAlign: TextAlign.center),
                if (code.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Fehlercode: $code',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (message.isNotEmpty && !anonymousDisabled) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
