import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kinova_mobile/screens/main_shell.dart';
import 'package:kinova_mobile/services/push_notification_service.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Rappel local « panier non finalisé », programmé sur l'appareil
/// (fonctionne aussi pour les clients non connectés et hors ligne).
class CartReminderService {
  CartReminderService._();

  static const delay = Duration(minutes: 30);
  static const _id = 7301;
  static const _payload = 'cart';

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        // L'autorisation est déjà demandée par PushNotificationService.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == _payload) _openCart();
      },
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true &&
        launch?.notificationResponse?.payload == _payload) {
      MainShell.requestedTab.value = MainShell.cartTab;
    }

    _ready = true;
  }

  /// Reprogramme le rappel : 30 min après la dernière modification du panier.
  static Future<void> schedule({
    required int itemCount,
    required String firstProductName,
  }) async {
    if (!_ready || itemCount <= 0) return;
    final body = itemCount == 1
        ? '« $firstProductName » est toujours dans votre panier. '
              'Finalisez votre commande en quelques instants, paiement à la livraison.'
        : 'Vos $itemCount articles sont toujours dans votre panier. '
              'Finalisez votre commande en quelques instants, paiement à la livraison.';
    try {
      await _plugin.cancel(id: _id);
      await _plugin.zonedSchedule(
        id: _id,
        scheduledDate: tz.TZDateTime.now(tz.UTC).add(delay),
        title: 'Votre panier KINOVA vous attend',
        body: body,
        payload: _payload,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'kinova_alerts',
            'Commandes et actualités',
            channelDescription:
                'Suivi des commandes, nouvelles commandes et offres KINOVA',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_notification',
            color: KinovaColors.gold,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentSound: true,
            sound: 'kinova_notification.caf',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Rappel panier non programmé : $e');
    }
  }

  static Future<void> cancel() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _id);
    } catch (_) {}
  }

  static void _openCart() {
    PushNotificationService.navigatorKey.currentState?.popUntil(
      (route) => route.isFirst,
    );
    MainShell.requestedTab.value = MainShell.cartTab;
  }
}
