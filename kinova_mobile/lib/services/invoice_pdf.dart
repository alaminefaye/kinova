import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kinova_mobile/models/models.dart';
import 'package:kinova_mobile/utils/format.dart';

const _brown = PdfColor.fromInt(0xFF2B1B14);
const _muted = PdfColor.fromInt(0xFF6B5446);
const _gold = PdfColor.fromInt(0xFF8C6A30);
const _line = PdfColor.fromInt(0xFFDCC8B4);
const _soft = PdfColor.fromInt(0xFFF6EEE6);
const _dark = PdfColor.fromInt(0xFF3E2723);

String invoiceFileName(Order order) =>
    'Facture-${order.invoiceNumber ?? order.id}.pdf'.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]'),
      '-',
    );

/// Les polices embarquées n'ont pas les espaces fines insécables
/// utilisées par NumberFormat('fr_FR').
String _money(num value) =>
    formatMoney(value).replaceAll('\u202f', ' ').replaceAll('\u00a0', ' ');

/// Polices statiques : le moteur PDF ne gère pas les polices variables
/// de l'app (il n'en garde que la graisse la plus fine).
Future<pw.Font> _font(String name) async =>
    pw.Font.ttf(await rootBundle.load('assets/fonts/pdf/$name.ttf'));

/// Réglages « Facture » du dashboard : pied de page et cachet (déjà téléchargé).
class InvoiceBranding {
  const InvoiceBranding({
    this.footer = 'KINOVA — Abidjan · kinovaci.com',
    this.stamp,
    this.stampLabel = '',
  });

  final String footer;
  final Uint8List? stamp;
  final String stampLabel;
}

Future<Uint8List> buildInvoicePdf(
  Order order, {
  InvoiceBranding branding = const InvoiceBranding(),
}) async {
  final regular = await _font('Montserrat-Regular');
  final semi = await _font('Montserrat-SemiBold');
  final bold = await _font('Montserrat-Bold');
  final serif = await _font('PlayfairDisplay-Bold');
  final logo = pw.MemoryImage(
    (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
  );
  pw.MemoryImage? stamp;
  if (branding.stamp != null) {
    try {
      stamp = pw.MemoryImage(branding.stamp!);
    } catch (_) {
      stamp = null;
    }
  }

  final date = DateFormat("dd/MM/yyyy 'à' HH:mm");
  final (label, color, note) = switch (order.invoiceStatus) {
    'confirmed' => (
      'FACTURE — PAYÉE',
      const PdfColor.fromInt(0xFF1B7A2E),
      'Paiement reçu. Cette facture est définitive. Merci pour votre confiance.',
    ),
    'cancelled' => (
      'COMMANDE ANNULÉE',
      const PdfColor.fromInt(0xFFC62828),
      'Cette commande a été annulée. Aucun montant n’est dû.',
    ),
    _ => (
      'FACTURE PROVISOIRE',
      const PdfColor.fromInt(0xFFB26A00),
      'Elle deviendra définitive dès réception du paiement.'
          '${order.isDelivery && order.shipping <= 0 ? ' Les frais de livraison se règlent directement au livreur.' : ''}',
    ),
  };

  pw.TextStyle t(double size, {PdfColor c = _brown, pw.Font? f}) =>
      pw.TextStyle(font: f ?? regular, fontSize: size, color: c);

  pw.Widget section(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.Text(
      text,
      style: t(8.5, c: _gold, f: bold).copyWith(letterSpacing: 1.5),
    ),
  );

  pw.Widget totalRow(String l, String v) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(l, style: t(10.5, c: _muted)),
        pw.Text(v, style: t(10.5, f: semi)),
      ],
    ),
  );

  final doc = pw.Document(
    title: invoiceFileName(order),
    author: 'KINOVA',
    creator: 'KINOVA',
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 32),
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      footer: (ctx) => pw.Column(
        children: [
          pw.Divider(color: _line, thickness: 0.8),
          if (branding.footer.trim().isNotEmpty)
            pw.Text(
              branding.footer.trim(),
              textAlign: pw.TextAlign.center,
              style: t(8.5, c: _muted).copyWith(lineSpacing: 1.5),
            ),
          if (ctx.pagesCount > 1)
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Page ${ctx.pageNumber}/${ctx.pagesCount}',
                style: t(8, c: _muted),
              ),
            ),
        ],
      ),
      build: (ctx) => [
        // En-tête
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: _dark,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.ClipRRect(
                horizontalRadius: 8,
                verticalRadius: 8,
                child: pw.Image(
                  logo,
                  width: 56,
                  height: 56,
                  fit: pw.BoxFit.cover,
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'KINOVA',
                      style: t(
                        26,
                        c: PdfColors.white,
                        f: serif,
                      ).copyWith(letterSpacing: 5),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Boutique KINOVA — Abidjan',
                      style: t(9.5, c: const PdfColor.fromInt(0xFFE8D7C8)),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(14),
                ),
                child: pw.Text(
                  label,
                  style: t(
                    9,
                    c: PdfColors.white,
                    f: bold,
                  ).copyWith(letterSpacing: 0.8),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Numéro et dates
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  section('FACTURE'),
                  pw.Text(
                    order.invoiceNumber ?? 'FAC-${order.id}',
                    style: t(15, f: bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text('Commande ${order.id}', style: t(10, c: _muted)),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                section('DATES'),
                pw.Text(
                  'Émise le ${date.format(order.createdAt.toLocal())}',
                  style: t(10),
                ),
                if (order.paidAt != null)
                  pw.Text(
                    'Payée le ${date.format(order.paidAt!.toLocal())}',
                    style: t(10, c: color, f: semi),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 16),

        // Client / Réception
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: _soft,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    section('CLIENT'),
                    pw.Text(
                      order.customerName ?? 'Client',
                      style: t(11, f: semi),
                    ),
                    if (order.customerPhone != null)
                      pw.Text(order.customerPhone!, style: t(10, c: _muted)),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    section('RÉCEPTION'),
                    pw.Text(
                      order.isDelivery
                          ? 'Livraison à domicile'
                          : 'Retrait en boutique KINOVA',
                      style: t(11, f: semi),
                    ),
                    if (order.isDelivery && order.address != null)
                      pw.Text(
                        [
                          order.address,
                          order.city,
                        ].whereType<String>().join(', '),
                        style: t(10, c: _muted),
                      ),
                    if (order.isDelivery && order.deliveryDetails != null)
                      pw.Text(order.deliveryDetails!, style: t(10, c: _muted)),
                    pw.Text(
                      'Paiement à la livraison / au retrait',
                      style: t(10, c: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 18),

        // Articles
        pw.TableHelper.fromTextArray(
          headers: ['ARTICLE', 'QTÉ', 'PRIX UNITAIRE', 'TOTAL'],
          data: [
            for (final item in order.items)
              [
                [
                  item.product.name,
                  if (item.selectedSize != null) 'Taille ${item.selectedSize}',
                  if (item.selectedColor != null)
                    'Couleur ${item.selectedColor}',
                ].join(' · '),
                '${item.quantity}',
                _money(item.product.price),
                _money(item.product.price * item.quantity),
              ],
          ],
          border: null,
          headerStyle: t(
            8.5,
            c: PdfColors.white,
            f: bold,
          ).copyWith(letterSpacing: 1),
          headerDecoration: const pw.BoxDecoration(color: _dark),
          cellStyle: t(10.5),
          headerPadding: const pw.EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 9,
          ),
          rowDecoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.8)),
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(5),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(2.3),
            3: const pw.FlexColumnWidth(2.3),
          },
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
        ),
        pw.SizedBox(height: 14),

        // Totaux
        pw.Row(
          children: [
            pw.Spacer(flex: 5),
            pw.Expanded(
              flex: 4,
              child: pw.Column(
                children: [
                  totalRow(
                    'Sous-total',
                    _money(order.subtotal > 0 ? order.subtotal : order.total),
                  ),
                  if (order.isDelivery)
                    totalRow(
                      'Livraison',
                      order.shipping > 0
                          ? _money(order.shipping)
                          : 'À régler au livreur',
                    ),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _dark,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL',
                          style: t(11, c: PdfColors.white, f: bold),
                        ),
                        pw.Text(
                          _money(order.total),
                          style: t(13, c: PdfColors.white, f: bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (stamp != null && order.invoiceStatus != 'cancelled') ...[
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              pw.Spacer(flex: 5),
              pw.Expanded(
                flex: 4,
                child: pw.Column(
                  children: [
                    pw.Image(
                      stamp,
                      width: 150,
                      height: 110,
                      fit: pw.BoxFit.contain,
                    ),
                    if (branding.stampLabel.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        branding.stampLabel.trim(),
                        style: t(9, c: _muted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
        pw.SizedBox(height: 20),

        // Mention
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _soft,
            border: pw.Border(left: pw.BorderSide(color: color, width: 4)),
          ),
          child: pw.Text(
            note,
            style: t(10.5, f: semi).copyWith(lineSpacing: 2),
          ),
        ),
      ],
    ),
  );

  return doc.save();
}
