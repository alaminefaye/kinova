import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/api/api_exception.dart';
import 'package:kinova_mobile/api/api_mappers.dart';
import 'package:kinova_mobile/screens/invoice_screen.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/utils/format.dart';
import 'package:kinova_mobile/widgets/kinova_loader.dart';

const _sheetBg = Color(0xFF22160F);
const _cardBg = Color(0xFF2C1D14);
const _divider = Color(0xFF3E2723);

const _statusOptions = <(String, String, Color)>[
  ('pending', 'En attente', Color(0xFFE65100)),
  ('processing', 'En préparation', Color(0xFF1565C0)),
  ('shipped', 'Expédiée / En livraison', Color(0xFF6A1B9A)),
  ('delivered', 'Livrée', Color(0xFF2E7D32)),
  ('cancelled', 'Annulée', Color(0xFFC62828)),
];

(String, Color) adminStatusStyle(String status) {
  for (final (key, label, color) in _statusOptions) {
    if (key == status) return (label, color);
  }
  return (status, KinovaColors.sand);
}

/// Fiche complète d'une commande pour l'admin : statut, paiement, suivi,
/// facture, note/motif d'annulation. Recharge la commande depuis l'API.
Future<void> showAdminOrderSheet(
  BuildContext context, {
  required String orderId,
  required VoidCallback onChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: _sheetBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AdminOrderSheet(orderId: orderId, onChanged: onChanged),
  );
}

class _AdminOrderSheet extends StatefulWidget {
  const _AdminOrderSheet({required this.orderId, required this.onChanged});

  final String orderId;
  final VoidCallback onChanged;

  @override
  State<_AdminOrderSheet> createState() => _AdminOrderSheetState();
}

class _AdminOrderSheetState extends State<_AdminOrderSheet> {
  Map<String, dynamic>? _order;
  String? _error;
  bool _saving = false;
  String? _feedback;
  bool _feedbackIsError = false;
  final _trackingCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _trackingCtrl.dispose();
    super.dispose();
  }

  void _apply(dynamic res) {
    if (res is Map && res['data'] is Map) {
      _order = Map<String, dynamic>.from(res['data'] as Map);
      _trackingCtrl.text = (_order!['tracking_number'] ?? '').toString();
    }
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final res = await context.read<ApiClient>().get(
        '/admin/orders/${widget.orderId}',
      );
      if (!mounted) return;
      setState(() => _apply(res));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible de charger la commande.');
      }
    }
  }

  Future<void> _update(Map<String, dynamic> body, String success) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _feedback = null;
    });
    try {
      final res = await context.read<ApiClient>().put(
        '/admin/orders/${widget.orderId}',
        body: body,
      );
      if (!mounted) return;
      setState(() {
        _apply(res);
        _feedback = success;
        _feedbackIsError = false;
      });
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedback = e is ApiException ? e.message : 'Erreur de mise à jour.';
        _feedbackIsError = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirm(String title, String message, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _sheetBg,
        title: Text(
          title,
          style: const TextStyle(color: KinovaColors.cream, fontSize: 16),
        ),
        content: Text(
          message,
          style: const TextStyle(color: KinovaColors.sand, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Retour',
              style: TextStyle(color: KinovaColors.sand),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              action,
              style: const TextStyle(
                color: Color(0xFFEF5350),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _setStatus(String status) async {
    final current = (_order?['status'] ?? '').toString();
    if (status == current) return;
    if (status == 'cancelled' &&
        !await _confirm(
          'Annuler la commande ?',
          'Le stock des articles sera remis en rayon et le client sera notifié.',
          'Annuler la commande',
        )) {
      return;
    }
    final (label, _) = adminStatusStyle(status);
    final autoPaid =
        status == 'delivered' && _order?['payment_status'] != 'paid';
    await _update(
      {'status': status},
      autoPaid
          ? 'Livrée et paiement encaissé — client notifié.'
          : 'Statut « $label » enregistré — client notifié.',
    );
  }

  Future<void> _togglePayment() async {
    final paid = _order?['payment_status'] == 'paid';
    if (paid &&
        !await _confirm(
          'Marquer comme non payée ?',
          'La facture redeviendra provisoire et le client sera notifié.',
          'Marquer non payée',
        )) {
      return;
    }
    await _update(
      {'payment_status': paid ? 'unpaid' : 'paid'},
      paid
          ? 'Paiement annulé — facture provisoire.'
          : 'Paiement enregistré — facture payée, client notifié.',
    );
  }

  Future<void> _saveTracking() async {
    FocusScope.of(context).unfocus();
    final value = _trackingCtrl.text.trim();
    if (value == (_order?['tracking_number'] ?? '').toString()) return;
    await _update(
      {'tracking_number': value.isEmpty ? null : value},
      value.isEmpty
          ? 'Numéro de suivi retiré.'
          : 'Numéro de suivi enregistré — client notifié.',
    );
  }

  String _date(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '');
    if (d == null) return '';
    return DateFormat("dd/MM/yyyy 'à' HH:mm").format(d.toLocal());
  }

  double _num(dynamic v) => double.tryParse('$v') ?? 0;

  @override
  Widget build(BuildContext context) {
    final order = _order;
    if (order == null) {
      return SizedBox(
        height: 320,
        child: Center(
          child: _error == null
              ? const KinovaLoader(message: 'Chargement...', size: 48)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(color: KinovaColors.cream),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _load,
                      child: const Text(
                        'Réessayer',
                        style: TextStyle(color: KinovaColors.gold),
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    final status = (order['status'] ?? 'pending').toString();
    final (statusLabel, statusColor) = adminStatusStyle(status);
    final paid = order['payment_status'] == 'paid';
    final cancelled = status == 'cancelled';
    final invoiceStatus = (order['invoice_status'] ?? '').toString();
    final (invoiceLabel, invoiceColor) = switch (invoiceStatus) {
      'confirmed' => ('Facture payée', const Color(0xFF66BB6A)),
      'cancelled' => ('Facture annulée', const Color(0xFFEF5350)),
      _ => ('Facture provisoire', KinovaColors.gold),
    };
    final phone = (order['customer_phone'] ?? '').toString();
    final isDelivery =
        order['is_delivery'] != false && order['is_delivery'] != 0;
    final address = [
      order['address'],
      order['city'],
    ].where((v) => v != null && '$v'.trim().isNotEmpty).join(', ');
    final details = (order['delivery_details'] ?? '').toString().trim();
    final mapsUrl = (order['maps_url'] ?? '').toString();
    final notes = (order['notes'] ?? '').toString().trim();
    final cancelledByCustomer = notes.contains('Annulée par le client');
    final items = order['items'] is List ? order['items'] as List : const [];
    final shipping = _num(order['shipping']);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KinovaColors.sand.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  (order['reference'] ?? '#${order['id']}').toString(),
                  style: const TextStyle(
                    color: KinovaColors.cream,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              Text(
                formatMoney(_num(order['total'])),
                style: const TextStyle(
                  color: KinovaColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Passée le ${_date(order['created_at'])}',
            style: const TextStyle(color: KinovaColors.sand, fontSize: 11.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Badge(label: statusLabel, color: statusColor),
              _Badge(
                label: paid ? 'Payée' : 'Non payée',
                color: paid ? const Color(0xFF66BB6A) : const Color(0xFFFF9800),
              ),
              _Badge(label: invoiceLabel, color: invoiceColor),
            ],
          ),
          if (_feedback != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    (_feedbackIsError
                            ? const Color(0xFFEF5350)
                            : const Color(0xFF66BB6A))
                        .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _feedback!,
                style: TextStyle(
                  color: _feedbackIsError
                      ? const Color(0xFFEF9A9A)
                      : const Color(0xFFA5D6A7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (_saving) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(
              color: KinovaColors.gold,
              backgroundColor: _divider,
            ),
          ],

          const _SectionTitle('CLIENT'),
          Text(
            (order['customer_name'] ?? 'Client').toString(),
            style: const TextStyle(
              color: KinovaColors.cream,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (phone.isNotEmpty)
            Text(
              phone,
              style: const TextStyle(color: KinovaColors.sand, fontSize: 12),
            ),

          const _SectionTitle('RÉCEPTION'),
          Text(
            isDelivery ? 'Livraison à domicile' : 'Retrait en boutique',
            style: const TextStyle(
              color: KinovaColors.cream,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (address.isNotEmpty)
            Text(
              address,
              style: const TextStyle(color: KinovaColors.sand, fontSize: 12),
            ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Précisions : $details',
              style: const TextStyle(
                color: KinovaColors.goldLight,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (phone.isNotEmpty)
                _ActionBtn(
                  icon: Icons.call_rounded,
                  label: 'Appeler',
                  onTap: () =>
                      launchUrl(Uri.parse('tel:${phone.replaceAll(' ', '')}')),
                ),
              if (mapsUrl.isNotEmpty)
                _ActionBtn(
                  icon: Icons.place_rounded,
                  label: 'Position GPS',
                  onTap: () => launchUrl(
                    Uri.parse(mapsUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              _ActionBtn(
                icon: Icons.receipt_long_rounded,
                label: invoiceLabel,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InvoiceScreen(
                      order: ApiMappers.order(order),
                      allowCancel: false,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (notes.isNotEmpty) ...[
            _SectionTitle(
              cancelledByCustomer ? 'MOTIF D\'ANNULATION CLIENT' : 'NOTE',
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cancelledByCustomer
                    ? const Color(0xFFEF5350).withValues(alpha: 0.12)
                    : _cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                notes,
                style: const TextStyle(
                  color: KinovaColors.cream,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],

          const _SectionTitle('PAIEMENT'),
          Row(
            children: [
              Expanded(
                child: Text(
                  paid
                      ? 'Payée${order['paid_at'] != null ? ' le ${_date(order['paid_at'])}' : ''}'
                      : 'À encaisser à la livraison / au retrait',
                  style: TextStyle(
                    color: paid ? const Color(0xFFA5D6A7) : KinovaColors.sand,
                    fontSize: 12.5,
                  ),
                ),
              ),
              if (paid || !cancelled)
                _ActionBtn(
                  icon: paid ? Icons.undo_rounded : Icons.payments_rounded,
                  label: paid ? 'Marquer non payée' : 'Marquer payée',
                  onTap: _saving ? null : _togglePayment,
                ),
            ],
          ),

          if (isDelivery && !cancelled) ...[
            const _SectionTitle('SUIVI DE LIVRAISON'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _trackingCtrl,
                    style: const TextStyle(
                      color: KinovaColors.cream,
                      fontSize: 13,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveTracking(),
                    decoration: InputDecoration(
                      hintText: 'N° de suivi ou nom du livreur',
                      hintStyle: TextStyle(
                        color: KinovaColors.sand.withValues(alpha: 0.5),
                        fontSize: 12.5,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: _cardBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: Icons.save_rounded,
                  label: 'Enregistrer',
                  onTap: _saving ? null : _saveTracking,
                ),
              ],
            ),
          ],

          const _SectionTitle('ARTICLES'),
          if (items.isEmpty)
            const Text(
              'Aucun détail d\'article',
              style: TextStyle(color: KinovaColors.sand, fontSize: 12),
            )
          else
            ...items.map((it) {
              final size = it['selected_size']?.toString();
              final color = it['selected_color']?.toString();
              final variant = [
                size,
                color,
              ].where((v) => v != null && v.isNotEmpty).join(' · ');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${it['quantity'] ?? 1} × ${it['product_name'] ?? 'Produit'}'
                        '${variant.isNotEmpty ? ' ($variant)' : ''}',
                        style: const TextStyle(
                          color: KinovaColors.cream,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    Text(
                      formatMoney(_num(it['line_total'] ?? it['unit_price'])),
                      style: const TextStyle(
                        color: KinovaColors.sand,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const Divider(color: _divider, height: 20),
          _TotalRow('Sous-total', formatMoney(_num(order['subtotal']))),
          _TotalRow(
            'Livraison',
            !isDelivery
                ? 'Retrait'
                : shipping > 0
                ? formatMoney(shipping)
                : 'À régler au livreur',
          ),
          _TotalRow('Total', formatMoney(_num(order['total'])), bold: true),

          const _SectionTitle('CHANGER LE STATUT'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (key, label, color) in _statusOptions)
                _StatusChip(
                  label: label,
                  color: color,
                  current: status == key,
                  onTap: _saving ? null : () => _setStatus(key),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                size: 14,
                color: KinovaColors.sand,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Le client reçoit une notification à chaque changement de statut, de paiement ou de suivi.',
                  style: TextStyle(
                    color: KinovaColors.sand.withValues(alpha: 0.8),
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: KinovaColors.gold,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: KinovaColors.gold),
      label: Text(
        label,
        style: const TextStyle(color: KinovaColors.cream, fontSize: 11.5),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: KinovaColors.gold.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.current,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool current;
  final VoidCallback? onTap;

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

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: bold ? KinovaColors.cream : KinovaColors.sand,
      fontSize: bold ? 14 : 12.5,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
