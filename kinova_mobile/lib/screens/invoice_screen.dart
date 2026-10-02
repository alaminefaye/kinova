import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kinova_mobile/models/models.dart';
import 'package:kinova_mobile/screens/orders_screen.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/utils/format.dart';

class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key, required this.order});

  final Order order;

  Future<void> _openPdf() async {
    final url = order.invoiceUrl;
    if (url == null) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm');
    final (label, color, note) = switch (order.invoiceStatus) {
      'confirmed' => (
        'FACTURE — PAYÉE',
        Colors.green,
        'Paiement reçu. Cette facture est définitive.',
      ),
      'cancelled' => (
        'COMMANDE ANNULÉE',
        Colors.red,
        'Cette commande a été annulée. Aucun montant n’est dû.',
      ),
      _ => (
        'FACTURE PROVISOIRE',
        const Color(0xFFB7791F),
        'Elle deviendra définitive dès réception du paiement.'
            '${order.isDelivery && order.shipping <= 0 ? ' Les frais de livraison se règlent directement au livreur.' : ''}',
      ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Facture')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: KinovaColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: KinovaColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'KINOVA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 20,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w700,
                          color: KinovaColors.brown,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  order.invoiceNumber ?? 'FAC-${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: KinovaColors.brown,
                  ),
                ),
                Text('Commande ${order.id}', style: _muted),
                Text(
                  'Émise le ${date.format(order.createdAt.toLocal())}',
                  style: _muted,
                ),
                if (order.paidAt != null)
                  Text(
                    'Payée le ${date.format(order.paidAt!.toLocal())}',
                    style: _muted,
                  ),
                const Divider(height: 26, color: KinovaColors.sand),
                if (order.customerName != null) ...[
                  const Text('CLIENT', style: _section),
                  const SizedBox(height: 4),
                  Text(order.customerName!, style: _body),
                  if (order.customerPhone != null)
                    Text(order.customerPhone!, style: _muted),
                  const SizedBox(height: 12),
                ],
                const Text('RÉCEPTION', style: _section),
                const SizedBox(height: 4),
                Text(
                  order.isDelivery
                      ? 'Livraison à domicile'
                      : 'Retrait en boutique KINOVA',
                  style: _body,
                ),
                if (order.isDelivery && order.address != null)
                  Text(
                    [order.address, order.city].whereType<String>().join(', '),
                    style: _muted,
                  ),
                if (order.isDelivery && order.deliveryDetails != null)
                  Text(order.deliveryDetails!, style: _muted),
                const Text(
                  'Paiement à la livraison / au retrait',
                  style: _muted,
                ),
                const Divider(height: 26, color: KinovaColors.sand),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.product.name} ×${item.quantity}',
                                style: _body,
                              ),
                              if (item.selectedSize != null ||
                                  item.selectedColor != null)
                                Text(
                                  [
                                    if (item.selectedSize != null)
                                      'Taille ${item.selectedSize}',
                                    if (item.selectedColor != null)
                                      'Couleur ${item.selectedColor}',
                                  ].join(' · '),
                                  style: _muted,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          formatMoney(item.product.price * item.quantity),
                          style: _body,
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 24, color: KinovaColors.sand),
                _row(
                  'Sous-total',
                  formatMoney(
                    order.subtotal > 0 ? order.subtotal : order.total,
                  ),
                ),
                if (order.isDelivery)
                  _row(
                    'Livraison',
                    order.shipping > 0
                        ? formatMoney(order.shipping)
                        : 'À régler au livreur',
                  ),
                const SizedBox(height: 4),
                _row('Total', formatMoney(order.total), bold: true),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    note,
                    style: const TextStyle(
                      fontSize: 12,
                      color: KinovaColors.brown,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (order.invoiceUrl != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _openPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('OUVRIR / ENREGISTRER EN PDF'),
            ),
          ],
          if (order.canCancel) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () async {
                final cancelled = await confirmCancelOrder(context, order);
                if (cancelled && context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('ANNULER LA COMMANDE'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC62828),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      color: KinovaColors.brown,
      fontSize: bold ? 16 : 13.5,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }

  static const _muted = TextStyle(color: KinovaColors.mutedBrown, fontSize: 12);
  static const _body = TextStyle(color: KinovaColors.brown, fontSize: 13.5);
  static const _section = TextStyle(
    color: KinovaColors.goldRich,
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
  );
}
