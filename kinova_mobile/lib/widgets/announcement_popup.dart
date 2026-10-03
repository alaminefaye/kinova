import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/api/api_config.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Annonce (image) gérée depuis le dashboard, affichée une fois par annonce
/// à l'ouverture de l'accueil.
class AnnouncementPopup {
  AnnouncementPopup._();

  static const _seenKey = 'kinova_announcement_seen';
  static bool _checkedThisSession = false;

  static Future<void> maybeShow(BuildContext context) async {
    if (_checkedThisSession) return;
    _checkedThisSession = true;

    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/announcement');
      final data = res is Map && res['data'] is Map
          ? Map<String, dynamic>.from(res['data'] as Map)
          : null;
      final rawUrl = data?['image_url']?.toString();
      if (data == null || rawUrl == null || rawUrl.isEmpty) return;

      final version = '${data['id']}_${data['updated_at']}';
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_seenKey) == version) return;

      final image = NetworkImage(ApiConfig.resolveMediaUrl(rawUrl));
      if (!context.mounted) return;
      await precacheImage(image, context);
      if (!context.mounted) return;

      await prefs.setString(_seenKey, version);
      unawaited(
        api.post('/announcement/${data['id']}/view').catchError((_) => null),
      );
      if (!context.mounted) return;
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Fermer',
        barrierColor: Colors.black.withValues(alpha: 0.6),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => _AnnouncementDialog(image: image),
        transitionBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeIn,
          );
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.9, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Annonce non affichée : $e');
    }
  }
}

class _AnnouncementDialog extends StatelessWidget {
  const _AnnouncementDialog({required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: size.height * 0.78,
            ),
            child: Stack(
              children: [
                Material(
                  color: Colors.transparent,
                  elevation: 12,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Image(image: image, fit: BoxFit.contain),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Fermer',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
