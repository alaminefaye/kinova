import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/api/api_exception.dart';
import 'package:kinova_mobile/models/models.dart';
import 'package:kinova_mobile/screens/invoice_screen.dart';
import 'package:kinova_mobile/state/auth_controller.dart';
import 'package:kinova_mobile/state/cart_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/utils/format.dart';
import 'package:kinova_mobile/widgets/kinova_loader.dart';

enum _OrderFilter {
  all('Toutes'),
  ongoing('En cours'),
  delivered('Livrées'),
  cancelled('Annulées');

  const _OrderFilter(this.label);
  final String label;

  bool matches(Order o) => switch (this) {
    _OrderFilter.all => true,
    _OrderFilter.ongoing => const [
      'pending',
      'processing',
      'shipped',
    ].contains(o.statusCode),
    _OrderFilter.delivered => o.statusCode == 'delivered',
    _OrderFilter.cancelled => o.statusCode == 'cancelled',
  };
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  _OrderFilter _filter = _OrderFilter.all;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final orders = await context.read<AuthController>().fetchOrders();
      if (mounted) context.read<CartController>().setOrders(orders);
    } catch (_) {
      // garde la liste déjà chargée
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<CartController>().orders;
    final visible = orders.where(_filter.matches).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in _OrderFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${f.label} (${orders.where(f.matches).length})',
                      ),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: KinovaColors.brown,
                      labelStyle: TextStyle(
                        color: _filter == f
                            ? KinovaColors.cream
                            : KinovaColors.brown,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                      showCheckmark: false,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: KinovaColors.brown,
              onRefresh: _refresh,
              child: _loading && orders.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        KinovaLoader(
                          size: 58,
                          compact: true,
                          message: 'Chargement des commandes',
                        ),
                      ],
                    )
                  : visible.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(32),
                      children: [
                        const SizedBox(height: 60),
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 48,
                          color: KinovaColors.sand,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          orders.isEmpty
                              ? 'Aucune commande pour le moment.'
                              : 'Aucune commande dans « ${_filter.label} ».',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: KinovaColors.mutedBrown),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: visible.length,
                      itemBuilder: (_, i) =>
                          OrderCard(order: visible[i], showCancel: true),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Couleur et libellé du badge de statut.
(Color, Color) orderStatusColors(String statusCode) => switch (statusCode) {
  'pending' => (const Color(0xFFFFF4D6), const Color(0xFF8A6200)),
  'processing' => (const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
  'shipped' => (const Color(0xFFEDE7F6), const Color(0xFF5E35B1)),
  'delivered' => (const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
  'cancelled' => (const Color(0xFFFDECEA), const Color(0xFFC62828)),
  _ => (KinovaColors.surfaceMuted, KinovaColors.brown),
};

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.showCancel = false});

  final Order order;
  final bool showCancel;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy');
    final (badgeBg, badgeFg) = orderStatusColors(order.statusCode);
    final invoiceLabel = switch (order.invoiceStatus) {
      'confirmed' => 'Facture confirmée',
      'cancelled' => 'Facture annulée',
      _ => 'Facture provisoire',
    };

    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => InvoiceScreen(order: order))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: KinovaColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: KinovaColors.cardShadow,
          border: Border.all(
            color: KinovaColors.gold.withValues(alpha: 0.16),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: KinovaColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: KinovaColors.brown,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.id,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: KinovaColors.brown,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.status,
                              style: TextStyle(
                                color: badgeFg,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${date.format(order.createdAt.toLocal())} · ${order.items.length} article${order.items.length > 1 ? 's' : ''}'
                              '${order.trackingNumber != null ? ' · ${order.trackingNumber}' : ''}',
                              style: const TextStyle(
                                color: KinovaColors.mutedBrown,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          Text(
                            formatMoney(order.total),
                            style: const TextStyle(
                              color: KinovaColors.brown,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            order.invoiceStatus == 'confirmed'
                                ? Icons.verified_rounded
                                : Icons.description_outlined,
                            size: 13,
                            color: KinovaColors.goldRich,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$invoiceLabel ›',
                            style: const TextStyle(
                              color: KinovaColors.goldRich,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showCancel && order.canCancel) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: () => confirmCancelOrder(context, order),
                  icon: const Icon(Icons.cancel_outlined, size: 15),
                  label: const Text('ANNULER LA COMMANDE'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828),
                    side: const BorderSide(color: Color(0xFFE57373)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Demande confirmation (avec motif), annule côté serveur et rafraîchit la liste.
/// Retourne true si la commande a été annulée.
Future<bool> confirmCancelOrder(BuildContext context, Order order) async {
  final reason = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: KinovaColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _CancelSheet(order: order),
  );
  if (reason == null || !context.mounted) return false;

  final auth = context.read<AuthController>();
  final cart = context.read<CartController>();
  final messenger = ScaffoldMessenger.of(context);
  try {
    await auth.cancelOrder(order.id, reason: reason);
    cart.setOrders(await auth.fetchOrders());
    messenger.showSnackBar(
      SnackBar(content: Text('Commande ${order.id} annulée.')),
    );
    return true;
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Annulation impossible. Réessayez.')),
    );
  }
  return false;
}

class _CancelSheet extends StatefulWidget {
  const _CancelSheet({required this.order});

  final Order order;

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  static const _reasons = [
    'J’ai changé d’avis',
    'Commande passée par erreur',
    'Je veux modifier ma commande',
    'Délai trop long',
    'Autre',
  ];

  String? _reason;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  void _submit() {
    final details = _details.text.trim();
    final parts = [
      if (_reason != null && _reason != 'Autre') _reason!,
      if (details.isNotEmpty) details,
    ];
    Navigator.of(context).pop(parts.join(' — '));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KinovaColors.sand,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Annuler la commande ${widget.order.id} ?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '${formatMoney(widget.order.total)} · ${widget.order.items.length} article${widget.order.items.length > 1 ? 's' : ''}. '
              'Cette action est définitive.',
              style: const TextStyle(color: KinovaColors.mutedBrown),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pourquoi annulez-vous ? (facultatif)',
              style: TextStyle(
                color: KinovaColors.brown,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in _reasons)
                  ChoiceChip(
                    label: Text(r),
                    selected: _reason == r,
                    onSelected: (s) => setState(() => _reason = s ? r : null),
                    selectedColor: KinovaColors.brown,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: _reason == r
                          ? KinovaColors.cream
                          : KinovaColors.brown,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _details,
              maxLength: 300,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Précisez si vous le souhaitez…',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('GARDER'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                    ),
                    child: const Text('ANNULER'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
