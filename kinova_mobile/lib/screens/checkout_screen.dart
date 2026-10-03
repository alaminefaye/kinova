import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kinova_mobile/api/api_exception.dart';
import 'package:kinova_mobile/screens/auth_screen.dart';
import 'package:kinova_mobile/screens/order_success_screen.dart';
import 'package:kinova_mobile/state/auth_controller.dart';
import 'package:kinova_mobile/state/cart_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/utils/format.dart';
import 'package:kinova_mobile/widgets/motion.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _details = TextEditingController();
  bool _isDelivery = false;
  bool _submitting = false;
  String? _error;

  Position? _position;
  bool _locating = false;
  String? _locationError;
  bool _locationNeedsSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      if (!auth.isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
        return;
      }
      final user = auth.user;
      if (user == null) return;
      setState(() {
        _name.text = user.name;
        _phone.text = user.phone ?? '';
        _address.text = user.address ?? '';
        _city.text = user.city ?? '';
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<bool> _askLocationConsent() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: KinovaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KinovaColors.sand.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: KinovaColors.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: KinovaColors.brown,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Partager votre position ?',
                style: TextStyle(
                  color: KinovaColors.brown,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'KINOVA a besoin de votre position actuelle pour que le livreur trouve votre adresse exacte.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: KinovaColors.mutedBrown,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              for (final (icon, text) in const [
                (
                  Icons.check_circle_outline_rounded,
                  'Utilisée une seule fois, pour cette commande',
                ),
                (
                  Icons.lock_outline_rounded,
                  'Visible uniquement par la boutique et le livreur',
                ),
                (Icons.location_off_outlined, 'Aucun suivi en arrière-plan'),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: KinovaColors.goldRich),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: KinovaColors.brown,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: KinovaColors.brown,
                        side: BorderSide(
                          color: KinovaColors.brown.withValues(alpha: 0.3),
                        ),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'PLUS TARD',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: KinovaColors.brown,
                        foregroundColor: KinovaColors.cream,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'AUTORISER',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return ok == true;
  }

  Future<void> _locate() async {
    if (_locating || !await _askLocationConsent() || !mounted) return;
    setState(() {
      _locating = true;
      _locationError = null;
      _locationNeedsSettings = false;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Activez la localisation (GPS) de votre téléphone.';
          _locationNeedsSettings = true;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        setState(
          () => _locationError =
              'Autorisez l’accès à la position pour la partager.',
        );
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Accès à la position refusé. Autorisez-le dans les réglages.';
          _locationNeedsSettings = true;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      setState(() => _position = position);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _locationError =
            'Position introuvable. Réessayez à l’extérieur ou près d’une fenêtre.',
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openSettings() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  Future<void> _openMap() async {
    final p = _position;
    if (p == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthController>();
      final order = await context.read<CartController>().placeOrder(
        customerName: _name.text.trim(),
        customerPhone: _phone.text.trim(),
        customerEmail: auth.user?.email,
        isDelivery: _isDelivery,
        address: _isDelivery
            ? _address.text.trim()
            : 'Retrait en boutique KINOVA',
        city: _isDelivery
            ? (_city.text.trim().isEmpty ? 'Abidjan' : _city.text.trim())
            : 'Abidjan',
        latitude: _isDelivery ? _position?.latitude : null,
        longitude: _isDelivery ? _position?.longitude : null,
        deliveryDetails: _isDelivery ? _details.text.trim() : null,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, _) => FadeTransition(
            opacity: animation,
            child: OrderSuccessScreen(order: order),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final settings = cart.settings;
    final shippingFee = cart.shippingFor(isDelivery: _isDelivery);
    final finalTotal = cart.subtotal + shippingFee;
    final courier = _isDelivery && settings.shippingPaidToCourier;

    final String shippingLabel;
    if (!_isDelivery) {
      shippingLabel = 'Retrait en boutique (gratuit)';
    } else if (courier) {
      shippingLabel = 'À régler au livreur';
    } else if (shippingFee == 0) {
      shippingLabel = settings.freeShippingEnabled
          ? 'Offerte (dès ${formatMoney(settings.freeShippingThreshold)})'
          : 'Offerte';
    } else {
      shippingLabel = formatMoney(shippingFee);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            FadeSlideIn(
              child: Text(
                'Mode de Réception & Coordonnées',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      hintText: 'Nom complet *',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: 'Téléphone *'),
                    validator: (v) =>
                        (v == null || v.trim().length < 8) ? 'Invalide' : null,
                  ),
                  const SizedBox(height: 14),
                  _DeliveryToggle(
                    value: _isDelivery,
                    subtitle: _isDelivery
                        ? (settings.shippingPaidToCourier
                              ? 'Frais à régler directement au livreur'
                              : 'Livraison à l’adresse indiquée')
                        : 'Option : sinon retrait en boutique KINOVA (gratuit)',
                    onChanged: (val) => setState(() => _isDelivery = val),
                  ),
                  if (_isDelivery) ...[
                    const SizedBox(height: 12),
                    _LocationCard(
                      position: _position,
                      locating: _locating,
                      error: _locationError,
                      needsSettings: _locationNeedsSettings,
                      onLocate: _locate,
                      onOpenSettings: _openSettings,
                      onOpenMap: _openMap,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address,
                      decoration: InputDecoration(
                        hintText: _position == null
                            ? 'Quartier / adresse de livraison *'
                            : 'Quartier / adresse (facultatif)',
                      ),
                      validator: (v) =>
                          _isDelivery &&
                              _position == null &&
                              (v == null || v.trim().isEmpty)
                          ? 'Indiquez une adresse ou partagez votre position'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _city,
                      decoration: const InputDecoration(
                        hintText: 'Ville (Abidjan par défaut)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _details,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText:
                            'Précisions pour le livreur : repères, immeuble, étage, couleur du portail…',
                      ),
                    ),
                    if (settings.shippingNote.trim().isNotEmpty)
                      _InfoNote(text: settings.shippingNote),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: Text(
                'Paiement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: _PayTile(
                title: _isDelivery
                    ? 'Paiement à la livraison'
                    : 'Paiement au retrait',
                subtitle: 'Espèces ou mobile money, à la réception du colis',
              ),
            ),
            const SizedBox(height: 28),
            FadeSlideIn(
              delay: const Duration(milliseconds: 220),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KinovaColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    _line('Articles', formatMoney(cart.subtotal)),
                    _line('Livraison', shippingLabel),
                    const Divider(color: KinovaColors.sand),
                    _line(
                      courier ? 'Total (hors livraison)' : 'Total à payer',
                      formatMoney(finalTotal),
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: const Duration(milliseconds: 280),
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: KinovaColors.cream,
                        ),
                      )
                    : const Text('CONFIRMER LA COMMANDE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _DeliveryToggle extends StatelessWidget {
  const _DeliveryToggle({
    required this.value,
    required this.subtitle,
    required this.onChanged,
  });

  final bool value;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: KinovaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? KinovaColors.gold.withValues(alpha: 0.6)
              : KinovaColors.sand.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            value ? Icons.local_shipping_rounded : Icons.storefront_rounded,
            color: value ? KinovaColors.goldRich : KinovaColors.mutedBrown,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Se faire livrer à domicile',
                  style: TextStyle(
                    color: KinovaColors.brown,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: KinovaColors.mutedBrown,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: KinovaColors.gold,
            activeTrackColor: KinovaColors.gold.withValues(alpha: 0.4),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.position,
    required this.locating,
    required this.error,
    required this.needsSettings,
    required this.onLocate,
    required this.onOpenSettings,
    required this.onOpenMap,
  });

  final Position? position;
  final bool locating;
  final String? error;
  final bool needsSettings;
  final VoidCallback onLocate;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final hasPosition = position != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KinovaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPosition
              ? Colors.green.withValues(alpha: 0.5)
              : KinovaColors.sand.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPosition
                    ? Icons.check_circle_rounded
                    : Icons.my_location_rounded,
                color: hasPosition ? Colors.green : KinovaColors.goldRich,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPosition
                          ? 'Position exacte enregistrée'
                          : 'Ma position exacte',
                      style: const TextStyle(
                        color: KinovaColors.brown,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasPosition
                          ? 'Précision ±${position!.accuracy.round()} m — le livreur vous trouvera directement.'
                          : 'Partagez votre position GPS pour que le livreur trouve votre adresse.',
                      style: const TextStyle(
                        color: KinovaColors.mutedBrown,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(color: Colors.red, fontSize: 11.5),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: locating ? null : onLocate,
                icon: locating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        hasPosition
                            ? Icons.refresh_rounded
                            : Icons.gps_fixed_rounded,
                        size: 16,
                      ),
                label: Text(
                  locating
                      ? 'Localisation…'
                      : (hasPosition ? 'Actualiser' : 'Utiliser ma position'),
                ),
              ),
              if (hasPosition)
                TextButton.icon(
                  onPressed: onOpenMap,
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Voir sur la carte'),
                ),
              if (needsSettings)
                TextButton(
                  onPressed: onOpenSettings,
                  child: const Text('Ouvrir les réglages'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KinovaColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: KinovaColors.goldRich,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: KinovaColors.brown,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayTile extends StatelessWidget {
  const _PayTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KinovaColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: KinovaColors.brown, width: 1.4),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.payments_outlined,
            color: KinovaColors.brown,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: KinovaColors.brown,
            size: 20,
          ),
        ],
      ),
    );
  }
}
