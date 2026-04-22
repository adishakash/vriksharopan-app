import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  debugPrint('Worker BG FCM: ${message.notification?.title}');
}

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'vrisharopan_worker',
    'Worker Notifications',
    importance: Importance.high,
  );

  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_bgHandler);
    await _fcm.requestPermission();
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _local.initialize(
        const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher')));

    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n == null) return;
      _local.show(
        n.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });

    final token = await _fcm.getToken();
    if (token != null) await StorageService.saveFcmToken(token);
  }
}
