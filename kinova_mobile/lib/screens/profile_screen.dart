import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/state/cart_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/utils/format.dart';
import 'package:kinova_mobile/widgets/motion.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<CartController>().orders;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Compte Privilège')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
        children: [
          // Carte VIP Membre KINOVA
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: KinovaColors.darkLuxuryGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: KinovaColors.brown.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: KinovaColors.gold.withOpacity(0.35),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: KinovaColors.gold,
                            width: 1.8,
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 26,
                          backgroundColor: KinovaColors.brown,
                          child: Text(
                            'K',
                            style: TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              color: KinovaColors.gold,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Membre VIP',
                                  style: TextStyle(
                                    color: KinovaColors.cream,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: KinovaColors.gold,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'OR',
                                    style: TextStyle(
                                      color: KinovaColors.brown,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'membre.vip@kinova.com',
                              style: TextStyle(
                                color: KinovaColors.sand,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      color: Color(0x33C5A080),
                      height: 1,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'FIDÉLITÉ KINOVA',
                            style: TextStyle(
                              color: KinovaColors.gold,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '1 450 Points',
                            style: TextStyle(
                              color: KinovaColors.cream,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: KinovaColors.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: KinovaColors.gold.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Mes Avantages',
                          style: TextStyle(
                            color: KinovaColors.cream,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // En-tête Commandes
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historique de Commandes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  '${orders.length} commande${orders.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: KinovaColors.mutedBrown,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Liste des Commandes (Cartes modernisées)
          if (orders.isEmpty)
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: KinovaColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: KinovaColors.cardShadow,
                  border: Border.all(
                    color: KinovaColors.gold.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KinovaColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: KinovaColors.sand,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aucune commande active',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Vos futurs achats apparaîtront ici.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...orders.asMap().entries.map((entry) {
              final i = entry.key;
              final order = entry.value;
              return FadeSlideIn(
                delay: Duration(milliseconds: 80 + i * 40),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KinovaColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: KinovaColors.cardShadow,
                    border: Border.all(
                      color: KinovaColors.gold.withOpacity(0.16),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: KinovaColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: KinovaColors.brown,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  order.id,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    order.status,
                                    style: const TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '${dateFormat.format(order.createdAt)} · ${order.items.length} article${order.items.length > 1 ? 's' : ''}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Spacer(),
                                Text(
                                  formatMoney(order.total),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: KinovaColors.brown,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 28),

          // Menu Actions & Services
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: KinovaColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: KinovaColors.cardShadow,
                border: Border.all(
                  color: KinovaColors.gold.withOpacity(0.16),
                  width: 1,
                ),
              ),
              child: Column(
                children: const [
                  _Tile(
                    icon: Icons.local_shipping_outlined,
                    title: 'Suivi de ma livraison',
                  ),
                  Divider(height: 1, indent: 48, color: KinovaColors.surfaceMuted),
                  _Tile(
                    icon: Icons.favorite_border_rounded,
                    title: 'Mes pièces enregistrées',
                  ),
                  Divider(height: 1, indent: 48, color: KinovaColors.surfaceMuted),
                  _Tile(
                    icon: Icons.help_outline_rounded,
                    title: 'Service Client & Assistance',
                  ),
                  Divider(height: 1, indent: 48, color: KinovaColors.surfaceMuted),
                  _Tile(
                    icon: Icons.info_outline_rounded,
                    title: 'Maison KINOVA & Engagements',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: KinovaColors.surfaceMuted,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: KinovaColors.brown, size: 18),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: KinovaColors.sand,
        size: 20,
      ),
      onTap: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: KinovaColors.brown,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              '$title — Service KINOVA actif',
              style: const TextStyle(color: KinovaColors.cream),
            ),
          ),
        );
      },
    );
  }
}

