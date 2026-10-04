import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/screens/notifications_screen.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const _soundChannel = MethodChannel('kinova/notification_sound');
  static ApiClient? _api;
  static bool _initialized = false;
  static bool _pendingOpen = false;

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Incrémenté à chaque push reçu : les écrans de notifications se rechargent.
  static final ValueNotifier<int> received = ValueNotifier<int>(0);

  static Future<void> init({ApiClient? api}) async {
    if (_initialized) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _api = api;

    await _requestPermission();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen((_) {
      received.value++;
      openNotifications();
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) _pendingOpen = true;

    _messaging.onTokenRefresh.listen((token) {
      _registerToken(token);
    });

    _initialized = true;
    unawaited(syncToken());
  }

  /// À appeler une fois l'écran principal affiché (app ouverte depuis une notification).
  static void consumePendingOpen() {
    if (!_pendingOpen) return;
    _pendingOpen = false;
    openNotifications();
  }

  static void openNotifications() {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }

  static void _onForegroundMessage(RemoteMessage message) {
    received.value++;

    // iOS affiche déjà la bannière système (avec le son) au premier plan.
    if (Platform.isIOS) return;

    _soundChannel.invokeMethod<void>('play').catchError((_) {});

    final title = message.notification?.title ?? 'KINOVA';
    final body = message.notification?.body ?? '';
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        backgroundColor: KinovaColors.brown,
        content: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logo.png',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: KinovaColors.goldLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (body.isNotEmpty)
                    Text(
                      body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: KinovaColors.cream,
                        fontSize: 12.5,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VOIR',
          textColor: KinovaColors.goldLight,
          onPressed: openNotifications,
        ),
      ),
    );
  }

  static Future<void> bindApi(ApiClient api) async {
    _api = api;
    await syncToken();
  }

  static Future<void> syncToken() async {
    if (_api?.token == null) return;
    try {
      if (Platform.isIOS && !await _waitForApnsToken()) {
        debugPrint(
          'FCM: jeton APNs indisponible (simulateur ou push non autorisé).',
        );
        return;
      }
      final token = await _messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  /// Sur iOS, getToken() échoue tant qu'Apple n'a pas fourni le jeton APNs.
  static Future<bool> _waitForApnsToken() async {
    for (var i = 0; i < 10; i++) {
      if (await _messaging.getAPNSToken() != null) return true;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  static Future<void> clearToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && _api?.token != null) {
        await _api!.post(
          '/customer/device-token/remove',
          body: {'token': token},
        );
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
      await _api!.post(
        '/customer/device-token',
        body: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );
    } catch (e) {
      debugPrint('FCM register error: $e');
    }
  }
}
