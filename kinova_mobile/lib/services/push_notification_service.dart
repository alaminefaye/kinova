import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:kinova_mobile/api/api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static ApiClient? _api;
  static bool _initialized = false;

  static Future<void> init({ApiClient? api}) async {
    if (_initialized) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _api = api;

    await _requestPermission();

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground: ${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM opened: ${message.notification?.title}');
    });

    _messaging.onTokenRefresh.listen((token) {
      _registerToken(token);
    });

    _initialized = true;
    await syncToken();
  }

  static Future<void> bindApi(ApiClient api) async {
    _api = api;
    await syncToken();
  }

  static Future<void> syncToken() async {
    if (_api?.token == null) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  static Future<void> clearToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && _api?.token != null) {
        await _api!.post('/customer/device-token/remove', body: {'token': token});
      }
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('FCM clear error: $e');
    }
  }

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static Future<void> _registerToken(String token) async {
    if (_api?.token == null) return;
    try {
      await _api!.post('/customer/device-token', body: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    } catch (e) {
      debugPrint('FCM register error: $e');
    }
  }
}
