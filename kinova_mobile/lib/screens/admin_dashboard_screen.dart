import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/api/api_config.dart';
import 'package:kinova_mobile/models/models.dart';
import 'package:kinova_mobile/screens/main_shell.dart';
import 'package:kinova_mobile/state/auth_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/utils/format.dart';
import 'package:kinova_mobile/widgets/kinova_loader.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late int _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  void _goToStore() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140D08),
      body: switch (_activeTab) {
        0 => _DashboardOverviewTab(onGoToStore: _goToStore),
        1 => const _AdminOrdersTab(),
        2 => const _AdminProductsTab(),
        3 => const _AdminMessagesTab(),
        _ => _DashboardOverviewTab(onGoToStore: _goToStore),
      },
      bottomNavigationBar: _AdminBottomNavBar(
        currentIndex: _activeTab,
        onTabSelected: (index) {
          if (index == 4) {
            _goToStore();
          } else {
            setState(() => _activeTab = index);
          }
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. BARRE DE NAVIGATION INFÉRIEURE ADMIN
// -----------------------------------------------------------------------------
class _AdminBottomNavBar extends StatelessWidget {
  const _AdminBottomNavBar({
    required this.currentIndex,
    required this.onTabSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E130D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: KinovaColors.gold.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              _AdminNavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
                active: currentIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _AdminNavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Commandes',
                active: currentIndex == 1,
                onTap: () => onTabSelected(1),
              ),
              _AdminNavItem(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2_rounded,
                label: 'Produits',
                active: currentIndex == 2,
                onTap: () => onTabSelected(2),
              ),
              _AdminNavItem(
                icon: Icons.mail_outline_rounded,
                activeIcon: Icons.mark_email_read_rounded,
                label: 'Messages',
                active: currentIndex == 3,
                onTap: () => onTabSelected(3),
              ),
              _AdminNavItem(
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront_rounded,
                label: 'Boutique',
                active: false,
                isStoreAction: true,
                onTap: () => onTabSelected(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.isStoreAction = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isStoreAction;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? KinovaColors.gold
        : (isStoreAction
            ? const Color(0xFFC5A080)
            : KinovaColors.sand.withValues(alpha: 0.65));

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: KinovaColors.gold.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: active
                      ? KinovaColors.gold.withValues(alpha: 0.16)
                      : (isStoreAction
                          ? const Color(0xFF332016)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  active ? activeIcon : icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. TAB 1 : DASHBOARD OVERVIEW (STATISTIQUES & KPIS)
// -----------------------------------------------------------------------------
class _DashboardOverviewTab extends StatefulWidget {
  const _DashboardOverviewTab({required this.onGoToStore});

  final VoidCallback onGoToStore;

  @override
  State<_DashboardOverviewTab> createState() => _DashboardOverviewTabState();
}

class _DashboardOverviewTabState extends State<_DashboardOverviewTab> {
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
          _error = 'Impossible de charger les statistiques.';
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
            content: Text('Erreur lors de la mise à jour'),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;

    return SafeArea(
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: KinovaColors.gold.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: KinovaColors.gold.withValues(alpha: 0.35),
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
                            const SizedBox(height: 12),
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
                              'Aperçu en direct des performances KINOVA',
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
                                label: 'Global',
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

                    // Graphique 7 jours (Zéro overflow)
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

                    // Alertes de Stock
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
    );
  }
}

// -----------------------------------------------------------------------------
// 3. TAB 2 : GESTION DES COMMANDES (_AdminOrdersTab) + CRÉATION MANUELLE
// -----------------------------------------------------------------------------
class _AdminOrdersTab extends StatefulWidget {
  const _AdminOrdersTab();

  @override
  State<_AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<_AdminOrdersTab> {
  bool _loading = true;
  String? _error;
  List<dynamic> _orders = [];
  String _selectedStatus = '';
  final _searchController = TextEditingController();

  final _statuses = const [
    {'key': '', 'label': 'Toutes'},
    {'key': 'pending', 'label': 'En attente'},
    {'key': 'processing', 'label': 'En préparation'},
    {'key': 'shipped', 'label': 'Expédiées'},
    {'key': 'delivered', 'label': 'Livrées'},
    {'key': 'cancelled', 'label': 'Annulées'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      String url = '/admin/orders?';
      if (_selectedStatus.isNotEmpty) {
        url += 'status=$_selectedStatus&';
      }
      if (_searchController.text.trim().isNotEmpty) {
        url += 'q=${Uri.encodeComponent(_searchController.text.trim())}&';
      }

      final res = await api.get(url);
      List<dynamic> list = [];
      if (res is Map && res['data'] is List) {
        list = res['data'] as List;
      }
      if (mounted) {
        setState(() {
          _orders = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les commandes.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateOrderStatus(dynamic orderId, String newStatus) async {
    try {
      final api = context.read<ApiClient>();
      await api.put('/admin/orders/$orderId', body: {'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commande mise à jour : $newStatus'),
            backgroundColor: KinovaColors.brown,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _fetchOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de mise à jour'),
            backgroundColor: Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final status = (order['status'] ?? 'pending').toString();
    final ref = (order['reference'] ?? '#CMD-${order['id']}').toString();
    final total = double.tryParse('${order['total']}') ?? 0.0;
    final custName = (order['customer_name'] ?? order['user']?['name'] ?? 'Client').toString();
    final custPhone = (order['customer_phone'] ?? order['user']?['phone'] ?? '').toString();
    final address = (order['address'] ?? '').toString();
    final city = (order['city'] ?? '').toString();
    final items = order['items'] is List ? (order['items'] as List) : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF22160F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollCtrl,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ref,
                        style: const TextStyle(
                          color: KinovaColors.cream,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        formatMoney(total),
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
                    'Client : $custName ${custPhone.isNotEmpty ? "($custPhone)" : ""}',
                    style: const TextStyle(color: KinovaColors.sand, fontSize: 13),
                  ),
                  if (address.isNotEmpty || city.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Livraison : $address, $city',
                      style: const TextStyle(color: KinovaColors.sand, fontSize: 12),
                    ),
                  ],
                  const Divider(color: Color(0xFF3E2723), height: 24),
                  const Text(
                    'Articles commandés :',
                    style: TextStyle(
                      color: KinovaColors.cream,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    const Text('Aucun détail d\'article',
                        style: TextStyle(color: KinovaColors.sand, fontSize: 12))
                  else
                    ...items.map((it) {
                      final name = (it['product_name'] ?? 'Produit').toString();
                      final qty = it['quantity'] ?? 1;
                      final price = double.tryParse('${it['unit_price'] ?? it['line_total']}') ?? 0.0;
                      final size = it['selected_size']?.toString();
                      final color = it['selected_color']?.toString();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '$qty x $name ${size != null ? "($size)" : ""} ${color != null ? "[$color]" : ""}',
                                style: const TextStyle(color: KinovaColors.cream, fontSize: 12.5),
                              ),
                            ),
                            Text(
                              formatMoney(price),
                              style: const TextStyle(color: KinovaColors.sand, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }),
                  const Divider(color: Color(0xFF3E2723), height: 24),
                  const Text(
                    'Changer le statut :',
                    style: TextStyle(
                      color: KinovaColors.cream,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusBtn(
                        label: 'En attente',
                        current: status == 'pending',
                        color: const Color(0xFFE65100),
                        onTap: () {
                          Navigator.pop(ctx);
                          _updateOrderStatus(order['id'], 'pending');
                        },
                      ),
                      _StatusBtn(
                        label: 'En préparation',
                        current: status == 'processing',
                        color: const Color(0xFF1565C0),
                        onTap: () {
                          Navigator.pop(ctx);
                          _updateOrderStatus(order['id'], 'processing');
                        },
                      ),
                      _StatusBtn(
                        label: 'Expédié / En livraison',
                        current: status == 'shipped',
                        color: const Color(0xFF6A1B9A),
                        onTap: () {
                          Navigator.pop(ctx);
                          _updateOrderStatus(order['id'], 'shipped');
                        },
                      ),
                      _StatusBtn(
                        label: 'Livré avec succès',
                        current: status == 'delivered',
                        color: const Color(0xFF2E7D32),
                        onTap: () {
                          Navigator.pop(ctx);
                          _updateOrderStatus(order['id'], 'delivered');
                        },
                      ),
                      _StatusBtn(
                        label: 'Annulé',
                        current: status == 'cancelled',
                        color: const Color(0xFFC62828),
                        onTap: () {
                          Navigator.pop(ctx);
                          _updateOrderStatus(order['id'], 'cancelled');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openCreateOrderModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A100A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CreateOrderModal(
        onSuccess: () {
          _fetchOrders();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commandes',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: KinovaColors.cream,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _openCreateOrderModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: KinovaColors.gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add_rounded, size: 18, color: KinovaColors.brown),
                            SizedBox(width: 4),
                            Text(
                              'Créer',
                              style: TextStyle(
                                color: KinovaColors.brown,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: _fetchOrders,
                      icon: const Icon(Icons.refresh_rounded, color: KinovaColors.sand),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _fetchOrders(),
              style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher par référence, client...',
                hintStyle: TextStyle(color: KinovaColors.sand.withValues(alpha: 0.5), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF22160F),
                prefixIcon: const Icon(Icons.search_rounded, color: KinovaColors.gold, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: KinovaColors.sand, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _fetchOrders();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: KinovaColors.sand.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: KinovaColors.sand.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Filtres Statut
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final st = _statuses[i];
                final selected = _selectedStatus == st['key'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedStatus = st['key']!);
                    _fetchOrders();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? KinovaColors.gold : const Color(0xFF22160F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? KinovaColors.gold : KinovaColors.sand.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      st['label']!,
                      style: TextStyle(
                        color: selected ? KinovaColors.brown : KinovaColors.cream,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Liste des commandes
          Expanded(
            child: _loading
                ? const Center(child: KinovaLoader(message: 'Chargement des commandes...', size: 48))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, style: const TextStyle(color: KinovaColors.cream)),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _fetchOrders,
                              style: ElevatedButton.styleFrom(backgroundColor: KinovaColors.gold),
                              child: const Text('Réessayer', style: TextStyle(color: KinovaColors.brown)),
                            ),
                          ],
                        ),
                      )
                    : _orders.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucune commande trouvée.',
                              style: TextStyle(color: KinovaColors.sand, fontSize: 13),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                            itemCount: _orders.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final o = Map<String, dynamic>.from(_orders[idx] as Map);
                              final ref = (o['reference'] ?? '#CMD-${o['id']}').toString();
                              final custName = (o['customer_name'] ?? o['user']?['name'] ?? 'Client').toString();
                              final total = double.tryParse('${o['total']}') ?? 0.0;
                              final status = (o['status'] ?? 'pending').toString();
                              final itemsCount = o['items_count'] ?? (o['items'] is List ? (o['items'] as List).length : 0);

                              DateTime createdAt;
                              try {
                                createdAt = DateTime.parse(o['created_at']?.toString() ?? '');
                              } catch (_) {
                                createdAt = DateTime.now();
                              }

                              final summary = AdminOrderSummary(
                                id: '${o['id']}',
                                reference: ref,
                                customerName: custName,
                                total: total,
                                status: status,
                                createdAt: createdAt,
                                itemsCount: itemsCount,
                              );

                              return _OrderListItem(
                                order: summary,
                                onTap: () => _showOrderDetails(o),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. TAB 3 : GESTION DES PRODUITS & STOCKS + CRÉATION / ÉDITION
// -----------------------------------------------------------------------------
class _AdminProductsTab extends StatefulWidget {
  const _AdminProductsTab();

  @override
  State<_AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<_AdminProductsTab> {
  bool _loading = true;
  String? _error;
  List<dynamic> _products = [];
  final _searchController = TextEditingController();
  int _stockFilter = 0; // 0: Tous, 1: Stock faible (<= 5), 2: Rupture (0)

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      String url = '/admin/products?';
      if (_searchController.text.trim().isNotEmpty) {
        url += 'q=${Uri.encodeComponent(_searchController.text.trim())}&';
      }

      final res = await api.get(url);
      List<dynamic> list = [];
      if (res is Map && res['data'] is List) {
        list = res['data'] as List;
      }
      if (mounted) {
        setState(() {
          _products = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les produits.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _adjustStock(dynamic productId, int currentStock, int delta) async {
    final newStock = (currentStock + delta).clamp(0, 99999);
    try {
      final api = context.read<ApiClient>();
      await api.put('/admin/products/$productId', body: {'stock': newStock});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock mis à jour : $newStock'),
            backgroundColor: KinovaColors.brown,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      await _fetchProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de mise à jour du stock'),
            backgroundColor: Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(dynamic productId, String productName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF22160F),
        title: const Text('Supprimer le produit', style: TextStyle(color: KinovaColors.cream)),
        content: Text('Êtes-vous sûr de vouloir supprimer "$productName" ?', style: const TextStyle(color: KinovaColors.sand)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: KinovaColors.sand)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    try {
      final api = context.read<ApiClient>();
      await api.delete('/admin/products/$productId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit supprimé avec succès'),
            backgroundColor: KinovaColors.brown,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _fetchProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openProductModal([Map<String, dynamic>? product]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A100A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ProductFormModal(
        product: product,
        onSuccess: () {
          _fetchProducts();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filtered = _products;
    if (_stockFilter == 1) {
      filtered = _products.where((p) {
        final stock = int.tryParse('${p['stock'] ?? 0}') ?? 0;
        return stock > 0 && stock <= 5;
      }).toList();
    } else if (_stockFilter == 2) {
      filtered = _products.where((p) {
        final stock = int.tryParse('${p['stock'] ?? 0}') ?? 0;
        return stock == 0;
      }).toList();
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Produits & Stocks',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: KinovaColors.cream,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openProductModal(null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: KinovaColors.gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add_rounded, size: 18, color: KinovaColors.brown),
                            SizedBox(width: 4),
                            Text(
                              'Nouveau',
                              style: TextStyle(
                                color: KinovaColors.brown,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: _fetchProducts,
                      icon: const Icon(Icons.refresh_rounded, color: KinovaColors.sand),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _fetchProducts(),
              style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                hintStyle: TextStyle(color: KinovaColors.sand.withValues(alpha: 0.5), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF22160F),
                prefixIcon: const Icon(Icons.search_rounded, color: KinovaColors.gold, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: KinovaColors.sand.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: KinovaColors.sand.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Filtres rapides stock
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                _StockFilterChip(
                  label: 'Tous (${_products.length})',
                  selected: _stockFilter == 0,
                  onTap: () => setState(() => _stockFilter = 0),
                ),
                const SizedBox(width: 8),
                _StockFilterChip(
                  label: 'Stock Faible (≤ 5)',
                  selected: _stockFilter == 1,
                  onTap: () => setState(() => _stockFilter = 1),
                ),
                const SizedBox(width: 8),
                _StockFilterChip(
                  label: 'Rupture (0)',
                  selected: _stockFilter == 2,
                  onTap: () => setState(() => _stockFilter = 2),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Liste des produits
          Expanded(
            child: _loading
                ? const Center(child: KinovaLoader(message: 'Chargement des produits...', size: 48))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: KinovaColors.cream)))
                    : filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun article trouvé.',
                              style: TextStyle(color: KinovaColors.sand, fontSize: 13),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final p = Map<String, dynamic>.from(filtered[idx] as Map);
                              final name = (p['name'] ?? '').toString();
                              final price = double.tryParse('${p['price']}') ?? 0.0;
                              final promoPrice = p['promo_price'] != null ? double.tryParse('${p['promo_price']}') : null;
                              final stock = int.tryParse('${p['stock'] ?? 0}') ?? 0;
                              final catName = (p['category']?['name'] ?? '').toString();
                              final rawImg = p['image_url']?.toString();
                              final imgUrl = (rawImg != null && rawImg.isNotEmpty) ? ApiConfig.resolveMediaUrl(rawImg) : null;

                              return GestureDetector(
                                onTap: () => _openProductModal(p),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22160F),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: stock == 0
                                          ? const Color(0xFFD32F2F).withValues(alpha: 0.5)
                                          : (stock <= 5
                                              ? const Color(0xFFFFA726).withValues(alpha: 0.4)
                                              : KinovaColors.sand.withValues(alpha: 0.18)),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          width: 52,
                                          height: 52,
                                          color: const Color(0xFF332016),
                                          child: imgUrl != null
                                              ? Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_rounded, color: KinovaColors.sand, size: 24))
                                              : const Icon(Icons.inventory_2_rounded, color: KinovaColors.sand, size: 24),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: KinovaColors.cream,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                if (catName.isNotEmpty)
                                                  Text(
                                                    '$catName • ',
                                                    style: const TextStyle(color: KinovaColors.sand, fontSize: 11),
                                                  ),
                                                Text(
                                                  formatMoney(promoPrice ?? price),
                                                  style: const TextStyle(
                                                    color: KinovaColors.gold,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            // Badge stock
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: stock == 0
                                                    ? const Color(0xFFD32F2F).withValues(alpha: 0.2)
                                                    : (stock <= 5
                                                        ? const Color(0xFFFFA726).withValues(alpha: 0.2)
                                                        : const Color(0xFF2E7D32).withValues(alpha: 0.2)),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                stock == 0 ? 'RUPTURE DE STOCK' : 'Stock : $stock unités',
                                                style: TextStyle(
                                                  color: stock == 0
                                                      ? const Color(0xFFEF5350)
                                                      : (stock <= 5
                                                          ? const Color(0xFFFFB74D)
                                                          : const Color(0xFF81C784)),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Boutons Actions & Ajusteur rapide de stock
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: const EdgeInsets.all(4),
                                            icon: const Icon(Icons.remove_circle_outline_rounded, color: KinovaColors.sand, size: 20),
                                            onPressed: stock > 0 ? () => _adjustStock(p['id'], stock, -1) : null,
                                            tooltip: 'Diminuer stock',
                                          ),
                                          IconButton(
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: const EdgeInsets.all(4),
                                            icon: const Icon(Icons.add_circle_outline_rounded, color: KinovaColors.gold, size: 20),
                                            onPressed: () => _adjustStock(p['id'], stock, 1),
                                            tooltip: 'Augmenter stock',
                                          ),
                                          IconButton(
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: const EdgeInsets.all(4),
                                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE57373), size: 18),
                                            onPressed: () => _deleteProduct(p['id'], name),
                                            tooltip: 'Supprimer',
                                          ),
                                        ],
                                      ),
                                    ],
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

class _StockFilterChip extends StatelessWidget {
  const _StockFilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? KinovaColors.gold : const Color(0xFF22160F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? KinovaColors.gold : KinovaColors.sand.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? KinovaColors.brown : KinovaColors.cream,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 5. TAB 4 : GESTION DES MESSAGES CLIENTS (_AdminMessagesTab)
// -----------------------------------------------------------------------------
class _AdminMessagesTab extends StatefulWidget {
  const _AdminMessagesTab();

  @override
  State<_AdminMessagesTab> createState() => _AdminMessagesTabState();
}

class _AdminMessagesTabState extends State<_AdminMessagesTab> {
  bool _loading = true;
  String? _error;
  List<dynamic> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/admin/contact-messages');
      List<dynamic> list = [];
      if (res is Map && res['data'] is List) {
        list = res['data'] as List;
      }
      if (mounted) {
        setState(() {
          _messages = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les messages.';
          _loading = false;
        });
      }
    }
  }

  void _showMessageDetails(Map<String, dynamic> msg) {
    final name = (msg['name'] ?? 'Expéditeur').toString();
    final email = (msg['email'] ?? '').toString();
    final phone = (msg['phone'] ?? '').toString();
    final subject = (msg['subject'] ?? 'Demande client').toString();
    final body = (msg['message'] ?? '').toString();
    final status = (msg['status'] ?? 'new').toString();

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
                    Expanded(
                      child: Text(
                        subject,
                        style: const TextStyle(
                          color: KinovaColors.cream,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'new'
                            ? const Color(0xFFFFA726).withValues(alpha: 0.2)
                            : const Color(0xFF66BB6A).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status == 'new' ? 'NOUVEAU' : 'LU',
                        style: TextStyle(
                          color: status == 'new' ? const Color(0xFFFFB74D) : const Color(0xFF81C784),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'De : $name • $email ${phone.isNotEmpty ? "($phone)" : ""}',
                  style: const TextStyle(color: KinovaColors.sand, fontSize: 12),
                ),
                const Divider(color: Color(0xFF3E2723), height: 24),
                const Text(
                  'Message :',
                  style: TextStyle(
                    color: KinovaColors.cream,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B110B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KinovaColors.sand.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    body,
                    style: const TextStyle(color: KinovaColors.cream, fontSize: 13, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Messages & Support',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: KinovaColors.cream,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                IconButton(
                  onPressed: _fetchMessages,
                  icon: const Icon(Icons.refresh_rounded, color: KinovaColors.sand),
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: KinovaLoader(message: 'Chargement des messages...', size: 48))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: KinovaColors.cream)))
                    : _messages.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun message reçu pour le moment.',
                              style: TextStyle(color: KinovaColors.sand, fontSize: 13),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                            itemCount: _messages.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final m = Map<String, dynamic>.from(_messages[idx] as Map);
                              final name = (m['name'] ?? 'Client').toString();
                              final subject = (m['subject'] ?? 'Demande').toString();
                              final body = (m['message'] ?? '').toString();
                              final status = (m['status'] ?? 'new').toString();

                              return GestureDetector(
                                onTap: () => _showMessageDetails(m),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22160F),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: status == 'new'
                                          ? KinovaColors.gold.withValues(alpha: 0.45)
                                          : KinovaColors.sand.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: KinovaColors.gold.withValues(alpha: 0.2),
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'M',
                                          style: const TextStyle(color: KinovaColors.gold, fontWeight: FontWeight.w800, fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    color: KinovaColors.cream,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (status == 'new')
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: KinovaColors.gold,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text(
                                                      'NOUVEAU',
                                                      style: TextStyle(color: KinovaColors.brown, fontSize: 8.5, fontWeight: FontWeight.w900),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              subject,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: KinovaColors.gold, fontSize: 11.5, fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              body,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: KinovaColors.sand.withValues(alpha: 0.8), fontSize: 11),
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
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 6. MODAL CRÉATION / ÉDITION DE PRODUIT (_ProductFormModal)
// -----------------------------------------------------------------------------
class _ProductFormModal extends StatefulWidget {
  const _ProductFormModal({this.product, required this.onSuccess});

  final Map<String, dynamic>? product;
  final VoidCallback onSuccess;

  @override
  State<_ProductFormModal> createState() => _ProductFormModalState();
}

class _ProductFormModalState extends State<_ProductFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _promoPriceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _sizesController;
  late TextEditingController _colorsController;

  int? _selectedCategoryId;
  List<dynamic> _categories = [];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?['name']?.toString() ?? '');
    _priceController = TextEditingController(text: p?['price']?.toString() ?? '');
    _promoPriceController = TextEditingController(text: p?['promo_price']?.toString() ?? '');
    _stockController = TextEditingController(text: p?['stock']?.toString() ?? '10');
    _descriptionController = TextEditingController(text: p?['description']?.toString() ?? '');
    _imageUrlController = TextEditingController(text: p?['image_url']?.toString() ?? '');

    // Formattage sizes & colors
    final sizesList = p?['sizes'] is List ? (p!['sizes'] as List) : [];
    final sizesStr = sizesList.map((s) => s is Map ? s['name'] : s.toString()).join(', ');
    _sizesController = TextEditingController(text: sizesStr);

    final colorsList = p?['colors'] is List ? (p!['colors'] as List) : [];
    final colorsStr = colorsList.map((c) => c is Map ? c['name'] : c.toString()).join(', ');
    _colorsController = TextEditingController(text: colorsStr);

    _selectedCategoryId = p?['category_id'] != null ? int.tryParse('${p!['category_id']}') : null;

    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/categories');
      if (res is Map && res['data'] is List) {
        if (mounted) {
          setState(() {
            _categories = res['data'] as List;
            if (_selectedCategoryId == null && _categories.isNotEmpty) {
              _selectedCategoryId = _categories.first['id'] as int;
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null && _categories.isNotEmpty) {
      _selectedCategoryId = _categories.first['id'] as int;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final isEdit = widget.product != null;

      final sizes = _sizesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map((s) => {'name': s, 'stock': null})
          .toList();

      final colors = _colorsController.text
          .split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .map((c) => {'name': c, 'hex': null, 'stock': null})
          .toList();

      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'category_id': _selectedCategoryId,
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        'description': _descriptionController.text.trim(),
        'image_url': _imageUrlController.text.trim(),
        'sizes': sizes,
        'colors': colors,
        'is_active': true,
        'is_new': true,
      };

      if (_promoPriceController.text.trim().isNotEmpty) {
        payload['promo_price'] = double.tryParse(_promoPriceController.text.trim());
      } else {
        payload['promo_price'] = null;
      }

      if (isEdit) {
        final id = widget.product!['id'];
        await api.put('/admin/products/$id', body: payload);
      } else {
        await api.post('/admin/products', body: payload);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Produit mis à jour avec succès' : 'Produit créé avec succès'),
            backgroundColor: KinovaColors.brown,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors de l\'enregistrement : $e';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Modifier le Produit' : 'Nouveau Produit KINOVA',
                      style: const TextStyle(
                        color: KinovaColors.cream,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: KinovaColors.sand),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Color(0xFFEF5350), fontSize: 12)),
                ],
                const Divider(color: Color(0xFF3E2723), height: 20),

                // Nom
                _buildInputLabel('Nom du Produit *'),
                TextFormField(
                  controller: _nameController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
                  style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
                  decoration: _buildInputDecoration('ex: Sérum Élixir Rose d’Or'),
                ),
                const SizedBox(height: 12),

                // Catégorie
                _buildInputLabel('Catégorie *'),
                if (_categories.isEmpty)
                  const Text('Chargement des catégories...', style: TextStyle(color: KinovaColors.sand, fontSize: 12))
                else
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    dropdownColor: const Color(0xFF22160F),
                    style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
                    decoration: _buildInputDecoration(''),
                    items: _categories.map((c) {
                      return DropdownMenuItem<int>(
                        value: c['id'] as int,
                        child: Text(c['name']?.toString() ?? 'Catégorie'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                  ),
                const SizedBox(height: 12),

                // Prix & Promo
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('Prix (FCFA) *'),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Prix obligatoire' : null,
                            style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
                            decoration: _buildInputDecoration('ex: 25000'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('Prix Promo (FCFA)'),
                          TextFormField(
                            controller: _promoPriceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
                            decoration: _buildInputDecoration('Optionnel'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stock
                _buildInputLabel('Quantité en Stock *'),
                TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Stock obligatoire' : null,
                  style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
                  decoration: _buildInputDecoration('ex: 50'),
                ),
                const SizedBox(height: 12),

                // Tailles & Couleurs
                _buildInputLabel('Tailles / Pointures (séparées par virgules)'),
                TextFormField(
                  controller: _sizesController,
                  style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
                  decoration: _buildInputDecoration('ex: S, M, L, XL ou 38, 39, 40'),
                ),
                const SizedBox(height: 12),

                _buildInputLabel('Couleurs (séparées par virgules)'),
                TextFormField(
                  controller: _colorsController,
                  style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
                  decoration: _buildInputDecoration('ex: Noir, Blanc, Or, Doré'),
                ),
                const SizedBox(height: 12),

                // Image URL
                _buildInputLabel('URL de l\'image'),
                TextFormField(
                  controller: _imageUrlController,
                  style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
                  decoration: _buildInputDecoration('https://... ou /images/...'),
                ),
                const SizedBox(height: 12),

                // Description
                _buildInputLabel('Description du produit'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
                  decoration: _buildInputDecoration('Description luxueuse de l\'article...'),
                ),
                const SizedBox(height: 20),

                // Bouton Valider
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KinovaColors.gold,
                      foregroundColor: KinovaColors.brown,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: KinovaColors.brown),
                          )
                        : Text(
                            isEdit ? 'Mettre à jour le Produit' : 'Créer le Produit',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: const TextStyle(
          color: KinovaColors.sand,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: KinovaColors.sand.withValues(alpha: 0.4), fontSize: 12.5),
      filled: true,
      fillColor: const Color(0xFF22160F),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KinovaColors.sand.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KinovaColors.sand.withValues(alpha: 0.2)),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 7. MODAL CRÉATION MANUELLE DE COMMANDE (_CreateOrderModal)
// -----------------------------------------------------------------------------
class _CreateOrderModal extends StatefulWidget {
  const _CreateOrderModal({required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  State<_CreateOrderModal> createState() => _CreateOrderModalState();
}

class _CreateOrderModalState extends State<_CreateOrderModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController(text: 'Abidjan');
  final _cityController = TextEditingController(text: 'Abidjan');
  final _notesController = TextEditingController();

  List<dynamic> _products = [];
  int? _selectedProductId;
  int _quantity = 1;
  String _paymentMethod = 'cash_on_delivery';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/admin/products');
      if (res is Map && res['data'] is List) {
        if (mounted) {
          setState(() {
            _products = res['data'] as List;
            if (_products.isNotEmpty) {
              _selectedProductId = _products.first['id'] as int;
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      setState(() => _error = 'Veuillez sélectionner au moins un article.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final payload = {
        'customer_name': _nameController.text.trim(),
        'customer_phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'payment_method': _paymentMethod,
        'status': 'pending',
        'notes': _notesController.text.trim(),
        'items': [
          {
            'product_id': _selectedProductId,
            'quantity': _quantity,
          }
        ],
      };

      await api.post('/admin/orders', body: payload);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande créée avec succès'),
            backgroundColor: KinovaColors.brown,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors de la création de la commande : $e';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nouvelle Commande',
                      style: TextStyle(
                        color: KinovaColors.cream,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: KinovaColors.sand),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Color(0xFFEF5350), fontSize: 12)),
                ],
                const Divider(color: Color(0xFF3E2723), height: 20),

                // Nom du Client
                _buildLabel('Nom du Client *'),
                TextFormField(
                  controller: _nameController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
                  style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
                  decoration: _buildDecor('ex: Aminata Touré'),
                ),
                const SizedBox(height: 12),

                // Téléphone
                _buildLabel('Téléphone Client *'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Téléphone obligatoire' : null,
                  style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
                  decoration: _buildDecor('ex: +225 07 00 00 00'),
                ),
                const SizedBox(height: 12),

                // Adresse & Ville
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Adresse de Livraison *'),
                          TextFormField(
                            controller: _addressController,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Adresse obligatoire' : null,
                            style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
                            decoration: _buildDecor('ex: Cocody Riviera Golf'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Ville'),
                          TextFormField(
                            controller: _cityController,
                            style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
                            decoration: _buildDecor('Abidjan'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Produit à commander
                _buildLabel('Article à commander *'),
                if (_products.isEmpty)
                  const Text('Chargement des articles...', style: TextStyle(color: KinovaColors.sand, fontSize: 12))
                else
                  DropdownButtonFormField<int>(
                    initialValue: _selectedProductId,
                    dropdownColor: const Color(0xFF22160F),
                    style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
                    decoration: _buildDecor(''),
                    items: _products.map((p) {
                      final price = double.tryParse('${p['promo_price'] ?? p['price']}') ?? 0.0;
                      return DropdownMenuItem<int>(
                        value: p['id'] as int,
                        child: Text('${p['name']} (${formatMoney(price)})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedProductId = val),
                  ),
                const SizedBox(height: 12),

                // Quantité
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('Quantité'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, color: KinovaColors.sand),
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(color: KinovaColors.cream, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: KinovaColors.gold),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Mode de paiement
                _buildLabel('Mode de Paiement'),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  dropdownColor: const Color(0xFF22160F),
                  style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
                  decoration: _buildDecor(''),
                  items: const [
                    DropdownMenuItem(value: 'cash_on_delivery', child: Text('Espèces à la livraison')),
                    DropdownMenuItem(value: 'wave', child: Text('Wave')),
                    DropdownMenuItem(value: 'orange_money', child: Text('Orange Money')),
                    DropdownMenuItem(value: 'card', child: Text('Carte Bancaire')),
                  ],
                  onChanged: (val) => setState(() => _paymentMethod = val ?? 'cash_on_delivery'),
                ),
                const SizedBox(height: 12),

                // Notes
                _buildLabel('Notes internes ou instructions'),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(color: KinovaColors.cream, fontSize: 13),
                  decoration: _buildDecor('ex: Appel avant livraison'),
                ),
                const SizedBox(height: 20),

                // Bouton Valider
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _createOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KinovaColors.gold,
                      foregroundColor: KinovaColors.brown,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: KinovaColors.brown),
                          )
                        : const Text(
                            'Créer la Commande',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          color: KinovaColors.sand,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  InputDecoration _buildDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: KinovaColors.sand.withValues(alpha: 0.4), fontSize: 12.5),
      filled: true,
      fillColor: const Color(0xFF22160F),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KinovaColors.sand.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KinovaColors.sand.withValues(alpha: 0.2)),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// COMPOSANTS REUTILISABLES (Cartes, Graphiques, Badges)
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
// GRAPHIQUE DES VENTES (SANS AUCUN OVERFLOW)
// -----------------------------------------------------------------------------
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
            height: 126,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: sales.map((s) {
                final ratio = maxAmount > 0 ? (s.amount / maxAmount) : 0.0;
                final barHeight = (ratio * 60).clamp(6.0, 60.0);
                final isToday = s.label == 'Auj.';

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 14,
                          child: s.amount > 0
                              ? Text(
                                  '${(s.amount / 1000).toStringAsFixed(0)}k',
                                  style: TextStyle(
                                    color: isToday
                                        ? KinovaColors.gold
                                        : KinovaColors.sand,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: isToday
                                ? KinovaColors.goldGradient
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFF8D6E63),
                                      Color(0xFF4E342E),
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
      'processing' => ('En préparation', const Color(0xFF42A5F5)),
      'shipped' => ('Expédié', const Color(0xFFAB47BC)),
      'delivered' => ('Livré', const Color(0xFF66BB6A)),
      _ => ('Annulé', const Color(0xFFEF5350)),
    };

    final d = order.createdAt.toLocal();
    const months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    final day = d.day.toString().padLeft(2, '0');
    final month = (d.month >= 1 && d.month <= 12) ? months[d.month - 1] : '';
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    final dateStr = '$day $month, $hour:$minute';

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          order.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: KinovaColors.cream,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
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
