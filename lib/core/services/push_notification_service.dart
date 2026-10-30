
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/notifications/notification_center_screen.dart';

/// Global navigator used for notification taps, including when Android launches
/// the app from a terminated state.
final GlobalKey<NavigatorState> quickSalonNavigatorKey =
    GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> quickSalonFirebaseBackgroundHandler(RemoteMessage message) async {
  // FCM notification payloads are displayed by Android while the app is in the
  // background/terminated. Keep this handler top-level for Android isolates.
  // Initialize Firebase here only if background code later needs Firebase APIs.
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _managementMode = false;
  String? _activeToken;
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'quicksalon_notifications',
    'QuickSalon notifications',
    description: 'Appointment updates, messages and reminders',
    importance: Importance.max,
  );

  Future<void> initialize({required bool managementMode}) async {
    if (_initialized) return;
    _managementMode = managementMode;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _openNotificationPage(response.payload);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    FirebaseMessaging.onBackgroundMessage(
      quickSalonFirebaseBackgroundHandler,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleRemoteTap(initialMessage);
      });
    }

    _messaging.onTokenRefresh.listen((token) {
      _saveToken(token);
    });

    Supabase.instance.client.auth.onAuthStateChange.listen((state) async {
      if (state.session?.user != null) {
        await registerCurrentDevice();
      }
    });

    _initialized = true;
    if (permission.authorizationStatus != AuthorizationStatus.denied) {
      await registerCurrentDevice();
    }
  }

  Future<void> registerCurrentDevice() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _saveToken(token);
    } catch (error) {
      debugPrint('QuickSalon push token registration failed: $error');
    }
  }

  Future<void> _saveToken(String token) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null || token.isEmpty) return;
    try {
      String? shopId;
      if (_managementMode) {
        final profile = await client
            .from('profiles')
            .select('shop_id,role')
            .eq('id', user.id)
            .maybeSingle();
        final role = profile?['role']?.toString();
        if (role == 'owner' || role == 'manager') {
          shopId = profile?['shop_id']?.toString();
        }
      }

      await client.from('notification_push_tokens').upsert(
        {
          'user_id': user.id,
          'shop_id': shopId,
          'token': token,
          'platform': 'android',
          'enabled': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'token',
      );
      _activeToken = token;
    } catch (error) {
      debugPrint('QuickSalon could not save push token: $error');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString() ?? 'QuickSalon';
    final body = notification?.body ?? message.data['body']?.toString() ?? 'You have an update.';
    await _localNotifications.show(
      message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          category: AndroidNotificationCategory.message,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleRemoteTap(RemoteMessage message) {
    _openNotificationPage(jsonEncode(message.data));
  }

  void _openNotificationPage(String? payload) {
    final navigator = quickSalonNavigatorKey.currentState;
    if (navigator == null) return;
    final data = <String, dynamic>{};
    if (payload != null && payload.isNotEmpty) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) {
          data.addAll(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationCenterScreen(
          managementMode: _managementMode,
          highlightedNotificationId: data['notification_id']?.toString(),
          appointmentId: data['appointment_id']?.toString(),
        ),
      ),
    );
  }
}
