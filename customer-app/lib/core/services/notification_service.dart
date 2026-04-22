import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM: ${message.notification?.title}');
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'vrisharopan_channel',
    'Vrisharopan Notifications',
    description: 'Tree updates, maintenance alerts, and more',
    importance: Importance.high,
  );

  static Future<void> init() async {
    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Create Android channel
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Local notifications init
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _local.initialize(initSettings);

    // Foreground notification display
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Save token
    final token = await _fcm.getToken();
    if (token != null) {
      await _syncFcmToken(token);
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen(_syncFcmToken);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  static Future<void> _syncFcmToken(String token) async {
    final stored = StorageService.getFcmToken();
    if (stored == token) return;

    await StorageService.saveFcmToken(token);

    // Only sync if logged in
    final accessToken = StorageService.getAccessToken();
    if (accessToken == null) return;

    try {
      await apiService.put(ApiConstants.fcmToken, data: {'fcm_token': token});
    } catch (_) {
      // Will retry on next launch
    }
  }
}
