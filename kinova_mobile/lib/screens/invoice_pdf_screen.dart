import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/models/models.dart';
import 'package:kinova_mobile/services/invoice_pdf.dart';
import 'package:kinova_mobile/state/catalog_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/kinova_loader.dart';

/// Aperçu du PDF de la facture généré dans l'app, avec enregistrement
/// (feuille de partage : Fichiers, Drive, WhatsApp…) et impression.
class InvoicePdfScreen extends StatefulWidget {
  const InvoicePdfScreen({super.key, required this.order});

  final Order order;

  @override
  State<InvoicePdfScreen> createState() => _InvoicePdfScreenState();
}

class _InvoicePdfScreenState extends State<InvoicePdfScreen> {
  late final Future<Uint8List> _pdf;

  @override
  void initState() {
    super.initState();
    _pdf = _build();
  }

  /// Recharge les réglages pour refléter un cachet / pied de page
  /// modifié depuis le dashboard ; sans réseau, la facture sort sans cachet.
  Future<Uint8List> _build() async {
    final catalog = context.read<CatalogController>();
    await catalog.refreshSettings();
    final settings = catalog.settings;

    Uint8List? stamp;
    final url = settings.invoiceStampUrl;
    if (url != null) {
      try {
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) stamp = res.bodyBytes;
      } catch (_) {}
    }

    return buildInvoicePdf(
      widget.order,
      branding: InvoiceBranding(
        footer: settings.invoiceFooter,
        stamp: stamp,
        stampLabel: settings.invoiceStampLabel,
      ),
    );
  }

  bool _busy = false;

  String get _fileName => invoiceFileName(widget.order);

  Future<void> _run(Future<void> Function(Uint8List bytes) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action(await _pdf);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de générer le PDF. Réessayez.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() =>
      _run((bytes) => Printing.sharePdf(bytes: bytes, filename: _fileName));

  Future<void> _print() => _run(
    (bytes) => Printing.layoutPdf(onLayout: (_) => bytes, name: _fileName),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facture PDF'),
        actions: [
          IconButton(
            tooltip: 'Imprimer',
            onPressed: _busy ? null : _print,
            icon: const Icon(Icons.print_outlined),
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => _pdf,
        useActions: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: _fileName,
        scrollViewDecoration: const BoxDecoration(
          color: KinovaColors.surfaceMuted,
        ),
        loadingWidget: const KinovaLoader(
          message: 'Préparation de la facture...',
          size: 48,
        ),
        onError: (_, _) => const Center(
          child: Text(
            'Impossible d’afficher la facture.',
            style: TextStyle(color: KinovaColors.brown),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 12),
        child: FilledButton.icon(
          onPressed: _busy ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: KinovaColors.brown,
            foregroundColor: KinovaColors.cream,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: KinovaColors.cream,
                  ),
                )
              : const Icon(Icons.download_rounded),
          label: const Text(
            'ENREGISTRER / PARTAGER LE PDF',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6),
          ),
        ),
      ),
    );
  }
}
