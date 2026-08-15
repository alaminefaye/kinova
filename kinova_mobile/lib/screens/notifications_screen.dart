import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/api/api_exception.dart';
import 'package:kinova_mobile/screens/auth_screen.dart';
import 'package:kinova_mobile/state/auth_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/kinova_loader.dart';
import 'package:kinova_mobile/widgets/motion.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  final String category;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.category,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'all';
  final List<NotificationItem> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthController>();
    if (!auth.isLoggedIn) {
      setState(() {
        _loading = false;
        _notifications.clear();
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await context.read<ApiClient>().get('/customer/notifications');
      final list = res is Map && res['data'] is List ? res['data'] as List : const [];
      final mapped = list.whereType<Map>().map((raw) {
        final json = Map<String, dynamic>.from(raw);
        final category = (json['category'] ?? 'system').toString();
        final created = DateTime.tryParse('${json['created_at']}');
        return NotificationItem(
          id: '${json['id']}',
          title: (json['title'] ?? '').toString(),
          message: (json['message'] ?? '').toString(),
          time: created != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(created.toLocal())
              : '',
          icon: _iconFor(category),
          iconColor: _colorFor(category),
          category: category,
          isRead: json['is_read'] == true || json['is_read'] == 1,
        );
      }).toList();

      setState(() {
        _notifications
          ..clear()
          ..addAll(mapped);
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(
        () => _error = 'Impossible de charger les notifications. Réessayez.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _iconFor(String category) {
    return switch (category) {
      'order' => Icons.local_shipping_rounded,
      'vip' => Icons.workspace_premium_rounded,
      'promo' => Icons.auto_awesome_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  Color _colorFor(String category) {
    return switch (category) {
      'order' => KinovaColors.brown,
      'vip' => KinovaColors.goldRich,
      'promo' => KinovaColors.gold,
      _ => KinovaColors.sand,
    };
  }

  List<NotificationItem> get _filteredNotifications {
    if (_selectedFilter == 'unread') {
      return _notifications.where((n) => !n.isRead).toList();
    } else if (_selectedFilter == 'order') {
      return _notifications.where((n) => n.category == 'order').toList();
    } else if (_selectedFilter == 'vip') {
      return _notifications
          .where((n) => n.category == 'vip' || n.category == 'promo')
          .toList();
    }
    return _notifications;
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (final item in _notifications) {
        item.isRead = true;
      }
    });
    try {
      await context.read<ApiClient>().post('/customer/notifications/read-all');
    } catch (_) {}
  }

  Future<void> _markRead(NotificationItem item) async {
    setState(() => item.isRead = true);
    try {
      await context
          .read<ApiClient>()
          .post('/customer/notifications/${item.id}/read');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          if (auth.isLoggedIn && unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(
                Icons.done_all_rounded,
                size: 16,
                color: KinovaColors.goldRich,
              ),
              label: const Text(
                'Tout lire',
                style: TextStyle(
                  color: KinovaColors.goldRich,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: !auth.isLoggedIn
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Connectez-vous pour vos notifications'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final ok = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      );
                      if (ok == true) _load();
                    },
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            )
          : _loading
              ? const KinovaLoader(message: 'Chargement des notifications')
              : Column(
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                          decoration: BoxDecoration(
                            color: KinovaColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: KinovaColors.gold.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                color: KinovaColors.brown,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: KinovaColors.brown,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _load,
                                style: TextButton.styleFrom(
                                  foregroundColor: KinovaColors.goldRich,
                                ),
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterPill(
                              label: 'Toutes (${_notifications.length})',
                              isSelected: _selectedFilter == 'all',
                              onTap: () => setState(() => _selectedFilter = 'all'),
                            ),
                            const SizedBox(width: 10),
                            _FilterPill(
                              label: 'Non lues ($unreadCount)',
                              isSelected: _selectedFilter == 'unread',
                              onTap: () =>
                                  setState(() => _selectedFilter = 'unread'),
                            ),
                            const SizedBox(width: 10),
                            _FilterPill(
                              label: 'Commandes',
                              isSelected: _selectedFilter == 'order',
                              onTap: () =>
                                  setState(() => _selectedFilter = 'order'),
                            ),
                            const SizedBox(width: 10),
                            _FilterPill(
                              label: 'Offres & VIP',
                              isSelected: _selectedFilter == 'vip',
                              onTap: () => setState(() => _selectedFilter = 'vip'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: _filteredNotifications.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 120),
                                  Center(child: Text('Aucune notification')),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                itemCount: _filteredNotifications.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = _filteredNotifications[index];
                                  return FadeSlideIn(
                                    delay: Duration(milliseconds: 50 * index),
                                    child: GestureDetector(
                                      onTap: () => _markRead(item),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: item.isRead
                                              ? KinovaColors.surface
                                                  .withValues(alpha: 0.7)
                                              : KinovaColors.surface,
                                          borderRadius: BorderRadius.circular(18),
                                          boxShadow: item.isRead
                                              ? []
                                              : KinovaColors.cardShadow,
                                          border: Border.all(
                                            color: item.isRead
                                                ? KinovaColors.gold
                                                    .withValues(alpha: 0.1)
                                                : KinovaColors.gold
                                                    .withValues(alpha: 0.35),
                                            width: item.isRead ? 0.8 : 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: item.iconColor
                                                    .withValues(alpha: 0.12),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                item.icon,
                                                color: item.iconColor,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          item.title,
                                                          style: TextStyle(
                                                            color:
                                                                KinovaColors.brown,
                                                            fontSize: 14,
                                                            fontWeight: item.isRead
                                                                ? FontWeight.w600
                                                                : FontWeight.w800,
                                                          ),
                                                        ),
                                                      ),
                                                      if (!item.isRead)
                                                        Container(
                                                          width: 8,
                                                          height: 8,
                                                          margin:
                                                              const EdgeInsets.only(
                                                            left: 6,
                                                          ),
                                                          decoration:
                                                              const BoxDecoration(
                                                            color: KinovaColors
                                                                .goldRich,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    item.message,
                                                    style: TextStyle(
                                                      color: KinovaColors
                                                          .mutedBrown,
                                                      fontSize: 12.5,
                                                      height: 1.35,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    item.time,
                                                    style: const TextStyle(
                                                      color: KinovaColors.sand,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
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

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? KinovaColors.brown : KinovaColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? KinovaColors.softShadow : [],
          border: Border.all(
            color: isSelected
                ? KinovaColors.brown
                : KinovaColors.gold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? KinovaColors.cream : KinovaColors.brown,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
