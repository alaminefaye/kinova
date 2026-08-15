import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool _isDelivery = true;
  String _payment = 'card';
  bool _submitting = false;
  String? _error;

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
    super.dispose();
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
            address: _isDelivery ? _address.text.trim() : 'Retrait en boutique KINOVA',
            city: _isDelivery ? _city.text.trim() : 'Abidjan',
            paymentMethod: _payment,
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
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final shippingFee = cart.shippingFor(isDelivery: _isDelivery);
    final finalTotal = cart.subtotal + shippingFee;

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
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(hintText: 'Nom complet *'),
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

                  // Option Se faire livrer (Toggle)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: KinovaColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isDelivery
                            ? KinovaColors.gold.withValues(alpha: 0.5)
                            : KinovaColors.sand.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isDelivery ? Icons.local_shipping_rounded : Icons.storefront_rounded,
                          color: _isDelivery ? KinovaColors.gold : KinovaColors.sand,
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
                                  color: KinovaColors.cream,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isDelivery
                                    ? 'Livraison sécurisée partout à Abidjan'
                                    : 'Retrait direct en boutique KINOVA (0 FCFA)',
                                style: TextStyle(
                                  color: _isDelivery ? KinovaColors.gold : KinovaColors.sand.withValues(alpha: 0.8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _isDelivery,
                          activeThumbColor: KinovaColors.gold,
                          activeTrackColor: KinovaColors.gold.withValues(alpha: 0.4),
                          onChanged: (val) => setState(() => _isDelivery = val),
                        ),
                      ],
                    ),
                  ),

                  // Champs adresse uniquement si livraison cochée
                  if (_isDelivery) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address,
                      decoration: const InputDecoration(hintText: 'Adresse de livraison complète *'),
                      validator: (v) => _isDelivery && (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _city,
                      decoration: const InputDecoration(hintText: 'Ville *'),
                      validator: (v) => _isDelivery && (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
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
              child: Column(
                children: [
                  _PayTile(
                    title: 'Carte bancaire',
                    subtitle: 'Visa, Mastercard',
                    value: 'card',
                    group: _payment,
                    onChanged: (v) => setState(() => _payment = v),
                  ),
                  _PayTile(
                    title: 'Paiement à la livraison / au retrait',
                    subtitle: 'Espèces ou mobile money',
                    value: 'cod',
                    group: _payment,
                    onChanged: (v) => setState(() => _payment = v),
                  ),
                ],
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
                    _line(
                      'Livraison',
                      shippingFee == 0
                          ? (_isDelivery ? 'Offerte (dès 50 000 FCFA)' : 'Retrait en boutique (Gratuit)')
                          : formatMoney(shippingFee),
                    ),
                    const Divider(color: KinovaColors.sand),
                    _line('Total', formatMoney(finalTotal), bold: true),
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
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _PayTile extends StatelessWidget {
  const _PayTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.group,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final String value;
  final String group;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = group == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: KinovaColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? KinovaColors.brown : KinovaColors.sand,
              width: selected ? 1.4 : 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: KinovaColors.brown,
                size: 20,
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
            ],
          ),
        ),
      ),
    );
  }
}
