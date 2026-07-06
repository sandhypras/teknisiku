import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _localReady = false;
  bool _listenersReady = false;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  Future<void> initialize() async {
    if (!_firebaseReady) return;
    await _requestPermission();
    await _initializeLocalNotifications();
    _registerForegroundListener();
  }

  Future<void> syncToken(String userId) async {
    if (!_firebaseReady || userId.isEmpty) return;
    try {
      await _requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.trim().isEmpty) return;
      await _saveToken(userId, token);
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _saveToken(userId, newToken);
      });
    } catch (_) {
      // Push notification is optional; never block login/home rendering.
    }
  }

  Future<void> deactivateCurrentToken(String userId) async {
    if (!_firebaseReady || userId.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await Supabase.instance.client
          .from('user_device_tokens')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('fcm_token', token);
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  Future<void> _requestPermission() async {
    if (!_firebaseReady) return;
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localReady || kIsWeb) return;
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(settings);

    const androidChannel = AndroidNotificationChannel(
      'siteknisi_orders',
      'Notifikasi Si Teknisi',
      description: 'Update order, pembayaran, dan verifikasi Si Teknisi',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
    _localReady = true;
  }

  void _registerForegroundListener() {
    if (_listenersReady) return;
    FirebaseMessaging.onMessage.listen((message) async {
      if (kIsWeb) return;
      await _initializeLocalNotifications();
      final notification = message.notification;
      final title = notification?.title ?? message.data['title'] as String?;
      final body = notification?.body ?? message.data['body'] as String?;
      if (title == null && body == null) return;
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'siteknisi_orders',
          'Notifikasi Si Teknisi',
          channelDescription:
              'Update order, pembayaran, dan verifikasi Si Teknisi',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _localNotifications.show(
        message.hashCode,
        title ?? 'Si Teknisi',
        body ?? '',
        details,
      );
    });
    _listenersReady = true;
  }

  Future<void> _saveToken(String userId, String token) async {
    await Supabase.instance.client.from('user_device_tokens').upsert({
      'user_id': userId,
      'fcm_token': token,
      'platform': _platformName(),
      'device_info': {'source': 'flutter'},
      'is_active': true,
      'last_seen_at': DateTime.now().toIso8601String(),
    }, onConflict: 'fcm_token');
  }
}

String _platformName() {
  if (kIsWeb) return 'web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux => 'linux',
    TargetPlatform.fuchsia => 'fuchsia',
  };
}
