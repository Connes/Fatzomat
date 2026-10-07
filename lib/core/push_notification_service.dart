import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/repositories/collaboration_repository.dart';
import '../data/repositories/push_device_repository.dart';
import '../features/settings/notifications_page.dart';
import '../features/shared/today_page.dart';
import '../features/recipes/recipe_detail_page.dart';
import '../data/repositories/recipe_repository.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Android renders notification payloads while the app is backgrounded or
  // terminated. Keep this handler intentionally light because no Flutter UI
  // context is available here.
}

class PushNotificationService with WidgetsBindingObserver {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  final PushDeviceRepository _devices = PushDeviceRepository();

  bool _initialized = false;
  bool _initializing = false;
  Timer? _tokenRetryTimer;
  bool _observingLifecycle = false;
  String? _pendingNotificationId;
  String? _pendingDecisionShareId;
  String? _pendingRecipeId;
  bool _navigationInFlight = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'schmackofatz_notifications',
    'Schmackofatz Benachrichtigungen',
    description: 'Nachrichten und Entscheidungen von deiner verbundenen Person.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized || _initializing) return;
    _initializing = true;

    try {
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _local.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: (response) {
          _handlePayload(response.payload);
        },
      );

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageTap);

      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _setPendingNavigation(initial.data);
        _flushPendingNavigation();
      }

      if (!_observingLifecycle) {
        WidgetsBinding.instance.addObserver(this);
        _observingLifecycle = true;
      }

      // Listen before the initial getToken() call so a startup token refresh
      // cannot leave the server without a usable device token.
      _messaging.onTokenRefresh.listen((token) async {
        try {
          await _devices.saveToken(token, platform: _platform);
        } catch (_) {
          _scheduleTokenRetry();
        }
      });

      _initialized = true;
      await _registerCurrentToken();
    } catch (_) {
      // Keep initialization retryable. A transient Firebase/permission/network
      // error must not permanently disable push for the rest of the process.
      _scheduleTokenRetry();
    } finally {
      _initializing = false;
    }
  }

  String get _platform => Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'other');

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _initialized) {
      _registerCurrentToken();
    }
  }

  Future<void> _registerCurrentToken() async {
    if (!_initialized && !_initializing) return;
    _tokenRetryTimer?.cancel();
    _tokenRetryTimer = null;

    try {
      final token = await _messaging
          .getToken()
          .timeout(const Duration(seconds: 15));
      if (token == null || token.trim().isEmpty) {
        _scheduleTokenRetry();
        return;
      }
      await _devices.saveToken(token, platform: _platform);
    } catch (_) {
      _scheduleTokenRetry();
    }
  }

  void _scheduleTokenRetry() {
    if (_tokenRetryTimer != null || !_initialized) return;
    _tokenRetryTimer = Timer(const Duration(seconds: 10), () {
      _tokenRetryTimer = null;
      _registerCurrentToken();
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title']?.toString() ?? 'Schmackofatz';
    final body = message.notification?.body ?? message.data['body']?.toString() ?? '';
    if (body.isEmpty) return;

    final id = _notificationId(message.data);
    await _local.show(
      id: id.hashCode & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
      payload: jsonEncode({
        'notification_id': id,
        'decision_share_id': message.data['decision_share_id']?.toString() ?? '',
        'recipe_id': message.data['recipe_id']?.toString() ?? '',
        'type': message.data['type']?.toString() ?? '',
      }),
    );
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    _setPendingNavigation(message.data);
    _flushPendingNavigation();
  }

  String? _notificationId(Map<String, dynamic> data) {
    final value = data['notification_id'] ?? data['id'];
    final id = value?.toString().trim();
    return id == null || id.isEmpty ? null : id;
  }

  void _handlePayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return;
    try {
      final map = jsonDecode(payload);
      if (map is Map) {
        _setPendingNavigation(Map<String, dynamic>.from(map));
        _flushPendingNavigation();
      }
    } catch (_) {
      _pendingNotificationId = payload.trim();
      _pendingDecisionShareId = null;
      _pendingRecipeId = null;
      _flushPendingNavigation();
    }
  }

  void _setPendingNavigation(Map<String, dynamic> data) {
    _pendingNotificationId = _notificationId(data);
    final shareId = data['decision_share_id']?.toString().trim();
    _pendingDecisionShareId = shareId == null || shareId.isEmpty ? null : shareId;
    final recipeId = data['recipe_id']?.toString().trim();
    _pendingRecipeId = recipeId == null || recipeId.isEmpty ? null : recipeId;
  }

  void attachNavigator() => _flushPendingNavigation();

  Future<void> _flushPendingNavigation() async {
    if (_navigationInFlight) return;
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    final id = _pendingNotificationId;
    final shareId = _pendingDecisionShareId;
    final recipeId = _pendingRecipeId;
    if (id == null && shareId == null && recipeId == null) return;

    _navigationInFlight = true;
    try {
      _pendingNotificationId = null;
      _pendingDecisionShareId = null;
      _pendingRecipeId = null;

      if (shareId != null) {
        if (id != null) {
          try {
            await CollaborationRepository().markNotificationRead(id);
          } catch (_) {
            // The Today page remains the primary action even if read-state
            // synchronization fails.
          }
        }
        navigator.push(MaterialPageRoute(builder: (_) => const TodayPage()));
        return;
      }

      if (recipeId != null) {
        try {
          final recipe = await RecipeRepository().getRecipeModel(recipeId);
          if (id != null) {
            try {
              await CollaborationRepository().markNotificationRead(id);
            } catch (_) {
              // The recipe remains the primary action even if read-state sync fails.
            }
          }
          navigator.push(MaterialPageRoute(builder: (_) => RecipeDetailPage(recipeId: recipe.id!)));
          return;
        } catch (_) {
          // Fall through to the notification inbox when the recipe was deleted
          // or cannot be loaded on this device.
        }
      }

      if (id != null) {
        navigator.push(
          MaterialPageRoute(builder: (_) => NotificationsPage(initialNotificationId: id)),
        );
      }
    } finally {
      _navigationInFlight = false;
    }
  }
}
