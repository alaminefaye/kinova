import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/screens/admin_order_sheet.dart';
import 'package:kinova_mobile/services/push_notification_service.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/kinova_loader.dart';

const _bg = Color(0xFF140D08);
const _card = Color(0xFF22160F);

class _AdminNotification {
  _AdminNotification(this.json)
    : isRead = json['is_read'] == true || json['is_read'] == 1;

  final Map<String, dynamic> json;
  bool isRead;

  String get id => '${json['id']}';
  String get title => (json['title'] ?? '').toString();
  String get message => (json['message'] ?? '').toString();
  Map<String, dynamic> get data =>
      json['data'] is Map ? Map<String, dynamic>.from(json['data']) : const {};
  String get type => (data['type'] ?? json['category'] ?? '').toString();
  String? get orderId => data['order_id']?.toString();
  DateTime? get createdAt => DateTime.tryParse('${json['created_at']}');
}

/// Notifications reçues par le compte admin connecté (nouvelles commandes,
/// annulations client…). Toucher une notification ouvre la commande.
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key, this.onOrdersChanged});

  final VoidCallback? onOrdersChanged;

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final List<_AdminNotification> _items = [];
  bool _loading = true;
  String? _error;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    PushNotificationService.received.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    PushNotificationService.received.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _error = null);
    try {
      final res = await context.read<ApiClient>().get(
        '/customer/notifications',
      );
      final list = res is Map && res['data'] is List
          ? res['data'] as List
          : const [];
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(
            list.whereType<Map>().map(
              (e) => _AdminNotification(Map<String, dynamic>.from(e)),
            ),
          );
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible de charger les notifications.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    setState(() {
      for (final n in _items) {
        n.isRead = true;
      }
    });
    try {
      await context.read<ApiClient>().post('/customer/notifications/read-all');
    } catch (_) {}
  }

  Future<void> _open(_AdminNotification n) async {
    if (!n.isRead) {
      setState(() => n.isRead = true);
      context
          .read<ApiClient>()
          .post('/customer/notifications/${n.id}/read')
          .catchError((_) => null);
    }
    final orderId = n.orderId;
    if (orderId != null) {
      await showAdminOrderSheet(
        context,
        orderId: orderId,
        onChanged: () => widget.onOrdersChanged?.call(),
      );
    }
  }

  (IconData, Color) _style(String type) => switch (type) {
    'admin_new_order' => (Icons.shopping_bag_rounded, const Color(0xFF66BB6A)),
    'admin_order_cancelled' => (Icons.cancel_rounded, const Color(0xFFEF5350)),
    'order' => (Icons.local_shipping_rounded, KinovaColors.gold),
    _ => (Icons.notifications_rounded, KinovaColors.sand),
  };

  String _time(DateTime? d) {
    if (d == null) return '';
    final local = d.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'À l’instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return DateFormat("dd/MM/yyyy 'à' HH:mm").format(local);
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((n) => !n.isRead).length;
    final visible = _unreadOnly
        ? _items.where((n) => !n.isRead).toList()
        : _items;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: KinovaColors.cream,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: KinovaColors.cream,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (unread > 0)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(
                Icons.done_all_rounded,
                size: 16,
                color: KinovaColors.gold,
              ),
              label: const Text(
                'Tout lire',
                style: TextStyle(color: KinovaColors.gold, fontSize: 12),
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const Center(
              child: KinovaLoader(message: 'Chargement...', size: 48),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                  child: Row(
                    children: [
                      _Chip(
                        label: 'Toutes (${_items.length})',
                        selected: !_unreadOnly,
                        onTap: () => setState(() => _unreadOnly = false),
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        label: 'Non lues ($unread)',
                        selected: _unreadOnly,
                        onTap: () => setState(() => _unreadOnly = true),
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFEF9A9A)),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    color: KinovaColors.gold,
                    onRefresh: _load,
                    child: visible.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 140),
                              Icon(
                                Icons.notifications_none_rounded,
                                size: 48,
                                color: KinovaColors.sand,
                              ),
                              SizedBox(height: 10),
                              Center(
                                child: Text(
                                  'Aucune notification',
                                  style: TextStyle(color: KinovaColors.sand),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                            itemCount: visible.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final n = visible[i];
                              final (icon, color) = _style(n.type);
                              return GestureDetector(
                                onTap: () => _open(n),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: n.isRead
                                        ? _card.withValues(alpha: 0.55)
                                        : _card,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: n.isRead
                                          ? KinovaColors.sand.withValues(
                                              alpha: 0.12,
                                            )
                                          : KinovaColors.gold.withValues(
                                              alpha: 0.45,
                                            ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          icon,
                                          color: color,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    n.title,
                                                    style: TextStyle(
                                                      color: KinovaColors.cream,
                                                      fontSize: 13.5,
                                                      fontWeight: n.isRead
                                                          ? FontWeight.w600
                                                          : FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                                if (!n.isRead)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    margin:
                                                        const EdgeInsets.only(
                                                          left: 6,
                                                        ),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Color(
                                                            0xFFE53935,
                                                          ),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              n.message,
                                              style: const TextStyle(
                                                color: KinovaColors.sand,
                                                fontSize: 12,
                                                height: 1.35,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Text(
                                                  _time(n.createdAt),
                                                  style: TextStyle(
                                                    color: KinovaColors.sand
                                                        .withValues(alpha: 0.7),
                                                    fontSize: 10.5,
                                                  ),
                                                ),
                                                if (n.orderId != null) ...[
                                                  const Spacer(),
                                                  const Text(
                                                    'Voir la commande ›',
                                                    style: TextStyle(
                                                      color: KinovaColors.gold,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? KinovaColors.gold : _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? KinovaColors.gold
                : KinovaColors.sand.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? KinovaColors.brown : KinovaColors.cream,
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
