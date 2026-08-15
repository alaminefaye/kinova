import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/models/models.dart';
import 'package:kinova_mobile/screens/main_shell.dart';
import 'package:kinova_mobile/state/auth_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/utils/format.dart';
import 'package:kinova_mobile/widgets/kinova_loader.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  String? _error;
  AdminDashboardData? _data;
  int _selectedPeriodIndex = 0; // 0: Auj., 1: 7 Jours, 2: Mois, 3: Global

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/admin/dashboard');
      if (res is Map && res['data'] is Map) {
        final parsed = AdminDashboardData.fromJson(
          Map<String, dynamic>.from(res['data'] as Map),
        );
        if (mounted) {
          setState(() {
            _data = parsed;
            _loading = false;
          });
        }
      } else {
        throw Exception('Format de réponse invalide');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger le tableau de bord administrateur.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      final api = context.read<ApiClient>();
      await api.put('/admin/orders/$orderId', body: {'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut commande mis à jour : $newStatus'),
            backgroundColor: KinovaColors.brown,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour du statut'),
            backgroundColor: Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showOrderActionSheet(AdminOrderSummary order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF22160F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.reference,
                      style: const TextStyle(
                        color: KinovaColors.cream,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      formatMoney(order.total),
                      style: const TextStyle(
                        color: KinovaColors.gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Client : ${order.customerName} ${order.customerPhone != null ? "(${order.customerPhone})" : ""}',
                  style: const TextStyle(color: KinovaColors.sand, fontSize: 13),
                ),
                const Divider(color: Color(0xFF3E2723), height: 28),
                const Text(
                  'Changer le statut de la commande :',
                  style: TextStyle(
                    color: KinovaColors.cream,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatusBtn(
                      label: 'En attente',
                      current: order.status == 'pending',
                      color: const Color(0xFFE65100),
                      onTap: () {
                        Navigator.pop(ctx);
                        _updateOrderStatus(order.id, 'pending');
                      },
                    ),
                    _StatusBtn(
                      label: 'En préparation',
                      current: order.status == 'processing',
                      color: const Color(0xFF1565C0),
                      onTap: () {
                        Navigator.pop(ctx);
                        _updateOrderStatus(order.id, 'processing');
                      },
                    ),
                    _StatusBtn(
                      label: 'Expédié / En livraison',
                      current: order.status == 'shipped',
                      color: const Color(0xFF6A1B9A),
                      onTap: () {
                        Navigator.pop(ctx);
                        _updateOrderStatus(order.id, 'shipped');
                      },
                    ),
                    _StatusBtn(
                      label: 'Livré avec succès',
                      current: order.status == 'delivered',
                      color: const Color(0xFF2E7D32),
                      onTap: () {
                        Navigator.pop(ctx);
                        _updateOrderStatus(order.id, 'delivered');
                      },
                    ),
                    _StatusBtn(
                      label: 'Annulé',
                      current: order.status == 'cancelled',
                      color: const Color(0xFFC62828),
                      onTap: () {
                        Navigator.pop(ctx);
                        _updateOrderStatus(order.id, 'cancelled');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goToStore() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFF140D08),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: KinovaLoader(
                  message: 'Chargement des statistiques...',
                  size: 64,
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: Color(0xFFE57373)),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: KinovaColors.cream),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadStats,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KinovaColors.gold,
                              foregroundColor: KinovaColors.brown,
                            ),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  )
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Barre supérieure : Rôle & Bascule Boutique
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          KinovaColors.gold.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: KinovaColors.gold
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.admin_panel_settings_rounded,
                                          size: 14,
                                          color: KinovaColors.gold,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          user?.isSuperAdmin == true
                                              ? 'SUPER-ADMIN'
                                              : 'ADMINISTRATEUR',
                                          style: const TextStyle(
                                            color: KinovaColors.gold,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      // Bouton Boutique
                                      GestureDetector(
                                        onTap: _goToStore,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2B1B14),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: KinovaColors.sand
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: const [
                                              Icon(
                                                Icons.storefront_rounded,
                                                size: 14,
                                                color: KinovaColors.cream,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Voir Boutique',
                                                style: TextStyle(
                                                  color: KinovaColors.cream,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Bouton Refresh
                                      IconButton(
                                        onPressed: _loadStats,
                                        icon: const Icon(
                                          Icons.refresh_rounded,
                                          color: KinovaColors.sand,
                                          size: 22,
                                        ),
                                        tooltip: 'Rafraîchir',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Titre
                              Text(
                                'Tableau de Bord',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: KinovaColors.cream,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Aperçu en direct de l’activité KINOVA',
                                style: TextStyle(
                                  color: KinovaColors.sand.withValues(alpha: 0.8),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Sélecteur de période
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _PeriodChip(
                                  label: 'Aujourd’hui',
                                  selected: _selectedPeriodIndex == 0,
                                  onTap: () =>
                                      setState(() => _selectedPeriodIndex = 0),
                                ),
                                _PeriodChip(
                                  label: '7 Derniers Jours',
                                  selected: _selectedPeriodIndex == 1,
                                  onTap: () =>
                                      setState(() => _selectedPeriodIndex = 1),
                                ),
                                _PeriodChip(
                                  label: 'Ce Mois-ci',
                                  selected: _selectedPeriodIndex == 2,
                                  onTap: () =>
                                      setState(() => _selectedPeriodIndex = 2),
                                ),
                                _PeriodChip(
                                  label: 'Global (Depuis le début)',
                                  selected: _selectedPeriodIndex == 3,
                                  onTap: () =>
                                      setState(() => _selectedPeriodIndex = 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 14)),

                      // Carte Héros Ventes
                      if (_data != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: _HeroSalesCard(
                              data: _data!,
                              periodIndex: _selectedPeriodIndex,
                            ),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 16)),

                      // Grille des 4 KPIs
                      if (_data != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.45,
                              children: [
                                _KpiCard(
                                  icon: Icons.shopping_bag_outlined,
                                  iconColor: const Color(0xFFFFA726),
                                  title: 'Commandes',
                                  value: '${_data!.ordersCount}',
                                  subValue:
                                      '${_data!.pendingOrders} en attente',
                                  subColor: _data!.pendingOrders > 0
                                      ? const Color(0xFFFF7043)
                                      : KinovaColors.sand,
                                ),
                                _KpiCard(
                                  icon: Icons.people_outline_rounded,
                                  iconColor: const Color(0xFF42A5F5),
                                  title: 'Clients Inscrits',
                                  value: '${_data!.totalCustomers}',
                                  subValue:
                                      '+${_data!.newCustomersToday} aujourd’hui',
                                  subColor: const Color(0xFF66BB6A),
                                ),
                                _KpiCard(
                                  icon: Icons.local_shipping_outlined,
                                  iconColor: const Color(0xFFAB47BC),
                                  title: 'En Livraison',
                                  value: '${_data!.processingOrders}',
                                  subValue: '${_data!.deliveredOrders} livrées',
                                  subColor: KinovaColors.sand,
                                ),
                                _KpiCard(
                                  icon: Icons.inventory_2_outlined,
                                  iconColor: const Color(0xFF26A69A),
                                  title: 'Articles Actifs',
                                  value: '${_data!.productsCount}',
                                  subValue:
                                      '${_data!.categoriesCount} univers/cat.',
                                  subColor: KinovaColors.sand,
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),

                      // Graphique des 7 derniers jours
                      if (_data != null && _data!.salesByDay.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: _SalesChartCard(
                              sales: _data!.salesByDay,
                            ),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),

                      // Alertes de Stock (si produits <= 5)
                      if (_data != null && _data!.lowStock.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: _LowStockSection(
                              lowStock: _data!.lowStock,
                            ),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),

                      // Dernières Commandes
                      if (_data != null && _data!.latestOrders.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Dernières Commandes',
                                      style: TextStyle(
                                        color: KinovaColors.cream,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${_data!.latestOrders.length} récentes',
                                      style: const TextStyle(
                                        color: KinovaColors.sand,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _data!.latestOrders.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final order = _data!.latestOrders[index];
                                    return _OrderListItem(
                                      order: order,
                                      onTap: () =>
                                          _showOrderActionSheet(order),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 36)),
                    ],
                  ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
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
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? KinovaColors.gold : const Color(0xFF231610),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? KinovaColors.gold
                : KinovaColors.sand.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? KinovaColors.brown : KinovaColors.cream,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _HeroSalesCard extends StatelessWidget {
  const _HeroSalesCard({
    required this.data,
    required this.periodIndex,
  });

  final AdminDashboardData data;
  final int periodIndex;

  @override
  Widget build(BuildContext context) {
    final double revenue;
    final int orders;
    final String label;

    switch (periodIndex) {
      case 0:
        revenue = data.todayRevenue;
        orders = data.todayOrdersCount;
        label = 'Ventes Aujourd’hui';
        break;
      case 1:
        revenue = data.salesByDay.fold(0.0, (sum, d) => sum + d.amount);
        orders = data.salesByDay.fold(0, (sum, d) => sum + d.count);
        label = 'Ventes des 7 Derniers Jours';
        break;
      case 2:
        revenue = data.monthRevenue;
        orders = data.monthOrdersCount;
        label = 'Ventes du Mois en Cours';
        break;
      default:
        revenue = data.totalRevenue;
        orders = data.ordersCount;
        label = 'Chiffre d’Affaires Global';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C1C13), Color(0xFF1B110B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KinovaColors.gold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: KinovaColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.show_chart_rounded,
                        size: 12, color: Color(0xFF81C784)),
                    const SizedBox(width: 4),
                    Text(
                      '$orders cmd.',
                      style: const TextStyle(
                        color: Color(0xFF81C784),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatMoney(revenue),
            style: const TextStyle(
              color: KinovaColors.cream,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFamily: 'serif',
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniBadge(
                label: 'En attente',
                value: '${data.pendingOrders}',
                color: const Color(0xFFFF9800),
              ),
              const SizedBox(width: 8),
              _MiniBadge(
                label: 'En cours',
                value: '${data.processingOrders}',
                color: const Color(0xFF42A5F5),
              ),
              const SizedBox(width: 8),
              _MiniBadge(
                label: 'Livrées',
                value: '${data.deliveredOrders}',
                color: const Color(0xFF66BB6A),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subValue,
    required this.subColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subValue;
  final Color subColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF22160F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KinovaColors.sand.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: KinovaColors.sand,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: KinovaColors.cream,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            subValue,
            style: TextStyle(
              color: subColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesChartCard extends StatelessWidget {
  const _SalesChartCard({required this.sales});

  final List<AdminDailySale> sales;

  @override
  Widget build(BuildContext context) {
    final maxAmount = sales.fold(
      1.0,
      (max, s) => s.amount > max ? s.amount : max,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF22160F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: KinovaColors.sand.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Tendance des Ventes (7 jours)',
                style: TextStyle(
                  color: KinovaColors.cream,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                Icons.bar_chart_rounded,
                color: KinovaColors.gold,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: sales.map((s) {
                final ratio = maxAmount > 0 ? (s.amount / maxAmount) : 0.0;
                final barHeight = (ratio * 75).clamp(6.0, 75.0);
                final isToday = s.label == 'Auj.';

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (s.amount > 0)
                          Text(
                            '${(s.amount / 1000).toStringAsFixed(0)}k',
                            style: TextStyle(
                              color: isToday
                                  ? KinovaColors.gold
                                  : KinovaColors.sand,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: isToday
                                ? KinovaColors.goldGradient
                                : LinearGradient(
                                    colors: [
                                      const Color(0xFF8D6E63),
                                      const Color(0xFF4E342E),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.label,
                          style: TextStyle(
                            color: isToday
                                ? KinovaColors.gold
                                : KinovaColors.sand,
                            fontSize: 10,
                            fontWeight:
                                isToday ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowStockSection extends StatelessWidget {
  const _LowStockSection({required this.lowStock});

  final List<AdminLowStockProduct> lowStock;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Alertes de Stock',
              style: TextStyle(
                color: KinovaColors.cream,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${lowStock.length} articles',
                style: const TextStyle(
                  color: Color(0xFFEF5350),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: lowStock.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final p = lowStock[index];
              return Container(
                width: 180,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF22160F),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: p.stock == 0
                        ? const Color(0xFFD32F2F).withValues(alpha: 0.5)
                        : const Color(0xFFFFA726).withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: KinovaColors.cream,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formatMoney(p.price),
                      style: const TextStyle(
                        color: KinovaColors.sand,
                        fontSize: 11,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: p.stock == 0
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFFFFA726).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.stock == 0 ? 'RUPTURE' : 'Reste : ${p.stock}',
                        style: TextStyle(
                          color: p.stock == 0
                              ? Colors.white
                              : const Color(0xFFFFB74D),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OrderListItem extends StatelessWidget {
  const _OrderListItem({
    required this.order,
    required this.onTap,
  });

  final AdminOrderSummary order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (order.status.toLowerCase()) {
      'pending' => ('En attente', const Color(0xFFFF9800)),
      'processing' => ('En cours', const Color(0xFF42A5F5)),
      'shipped' => ('Expédié', const Color(0xFFAB47BC)),
      'delivered' => ('Livré', const Color(0xFF66BB6A)),
      _ => ('Annulé', const Color(0xFFEF5350)),
    };

    final dateStr = DateFormat('dd MMM, HH:mm', 'fr_FR').format(order.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF22160F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: KinovaColors.sand.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            // Initiale Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: KinovaColors.gold.withValues(alpha: 0.2),
              child: Text(
                order.customerName.isNotEmpty
                    ? order.customerName[0].toUpperCase()
                    : 'C',
                style: const TextStyle(
                  color: KinovaColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          color: KinovaColors.cream,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        formatMoney(order.total),
                        style: const TextStyle(
                          color: KinovaColors.gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${order.reference} • $dateStr',
                        style: const TextStyle(
                          color: KinovaColors.sand,
                          fontSize: 10.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
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
  }
}

class _StatusBtn extends StatelessWidget {
  const _StatusBtn({
    required this.label,
    required this.current,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool current;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: current ? color : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: current ? Colors.white : color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
