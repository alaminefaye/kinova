import 'package:flutter/material.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/motion.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  final String category; // 'order', 'vip', 'promo'
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

  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: 'n1',
      title: 'Commande #KN-8492 Expédiée 📦',
      message:
          'Votre commande contenant le Sérum Rose Dorée a été confiée à Chronopost. Numéro de suivi : 6A0948271.',
      time: 'Il y a 2h',
      icon: Icons.local_shipping_rounded,
      iconColor: KinovaColors.brown,
      category: 'order',
      isRead: false,
    ),
    NotificationItem(
      id: 'n2',
      title: 'Bonus VIP KINOVA Crédité 👑',
      message:
          'Félicitations ! Vos +200 Points de fidélité ont été crédités sur votre compte suite à votre dernier achat.',
      time: 'Hier, 16:45',
      icon: Icons.workspace_premium_rounded,
      iconColor: KinovaColors.goldRich,
      category: 'vip',
      isRead: false,
    ),
    NotificationItem(
      id: 'n3',
      title: 'Nouvelle Collection 2026 ✨',
      message:
          'Découvrez notre nouvelle ligne de soins d’exception et d’accessoires en cuir grainé couleur sable.',
      time: 'Il y a 2 jours',
      icon: Icons.auto_awesome_rounded,
      iconColor: KinovaColors.gold,
      category: 'promo',
      isRead: false,
    ),
    NotificationItem(
      id: 'n4',
      title: 'Livraison Confirmée ✔️',
      message:
          'Votre colis pour la commande #KN-8210 a été déposé dans votre boîte aux lettres avec succès.',
      time: 'Il y a 5 jours',
      icon: Icons.check_circle_outline_rounded,
      iconColor: Colors.green.shade700,
      category: 'order',
      isRead: true,
    ),
  ];

  List<NotificationItem> get _filteredNotifications {
    if (_selectedFilter == 'unread') {
      return _notifications.where((n) => !n.isRead).toList();
    } else if (_selectedFilter == 'order') {
      return _notifications.where((n) => n.category == 'order').toList();
    } else if (_selectedFilter == 'vip') {
      return _notifications.where((n) => n.category == 'vip' || n.category == 'promo').toList();
    }
    return _notifications;
  }

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toutes les notifications ont été marquées comme lues.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
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
      body: Column(
        children: [
          // Pills de filtrage
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
                    onTap: () => setState(() => _selectedFilter = 'unread'),
                  ),
                  const SizedBox(width: 10),
                  _FilterPill(
                    label: 'Commandes',
                    isSelected: _selectedFilter == 'order',
                    onTap: () => setState(() => _selectedFilter = 'order'),
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

          // Liste des Notifications
          Expanded(
            child: _filteredNotifications.isEmpty
                ? Center(
                    child: FadeSlideIn(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: KinovaColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: KinovaColors.cardShadow,
                            ),
                            child: const Icon(
                              Icons.notifications_off_outlined,
                              size: 44,
                              color: KinovaColors.sand,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Aucune notification',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Vous êtes à jour ! Vos notifications apparaîtront ici.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredNotifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _filteredNotifications[index];
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 50 * index),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              item.isRead = true;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: item.isRead
                                  ? KinovaColors.surface.withOpacity(0.7)
                                  : KinovaColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: item.isRead ? [] : KinovaColors.cardShadow,
                              border: Border.all(
                                color: item.isRead
                                    ? KinovaColors.gold.withOpacity(0.1)
                                    : KinovaColors.gold.withOpacity(0.35),
                                width: item.isRead ? 0.8 : 1.2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icône de catégorie
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: item.iconColor.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: item.iconColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Détails
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: TextStyle(
                                                color: KinovaColors.brown,
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
                                              margin: const EdgeInsets.only(left: 6),
                                              decoration: const BoxDecoration(
                                                color: KinovaColors.goldRich,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.message,
                                        style: TextStyle(
                                          color: item.isRead
                                              ? KinovaColors.mutedBrown.withOpacity(0.7)
                                              : KinovaColors.mutedBrown,
                                          fontSize: 12.5,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item.time,
                                        style: TextStyle(
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
                : KinovaColors.gold.withOpacity(0.2),
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
