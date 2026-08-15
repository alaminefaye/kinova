import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kinova_mobile/screens/auth_screen.dart';
import 'package:kinova_mobile/screens/checkout_screen.dart';
import 'package:kinova_mobile/state/auth_controller.dart';
import 'package:kinova_mobile/state/cart_controller.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/utils/format.dart';
import 'package:kinova_mobile/widgets/motion.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Panier')),
      body: cart.items.isEmpty
          ? Center(
              child: FadeSlideIn(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 56,
                      color: KinovaColors.sand,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Votre panier est vide',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoutez des pièces que vous aimez',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 40 * index),
                        child: Dismissible(
                          key: Key('${item.product.id}-${item.selectedSize}-${item.selectedColor}-$index'),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => cart.removeItem(item),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 22),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC62828),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          child: Container(
                          padding: const EdgeInsets.all(12),
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  width: 82,
                                  height: 82,
                                  child: SoftNetworkImage(
                                    url: item.product.imageUrl,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if (item.selectedSize != null || item.selectedColor != null) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 5,
                                        runSpacing: 4,
                                        children: [
                                          if (item.selectedSize != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: KinovaColors.sand.withOpacity(0.25),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Taille : ${item.selectedSize}',
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: KinovaColors.brown,
                                                ),
                                              ),
                                            ),
                                          if (item.selectedColor != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: KinovaColors.sand.withOpacity(0.25),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Couleur : ${item.selectedColor}',
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: KinovaColors.brown,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    if (item.product.hasPromo)
                                      Row(
                                        children: [
                                          Text(
                                            formatMoney(item.product.price),
                                            style: const TextStyle(
                                              color: Color(0xFF9E8E82),
                                              fontSize: 11,
                                              decoration: TextDecoration.lineThrough,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            formatMoney(item.product.effectivePrice),
                                            style: const TextStyle(
                                              color: Color(0xFFB71C1C),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Text(
                                        formatMoney(item.product.price),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: KinovaColors.brown,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: KinovaColors.surfaceMuted,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: KinovaColors.gold
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _MiniQty(
                                                icon: Icons.remove_rounded,
                                                onTap: () => cart.setItemQuantity(
                                                  item,
                                                  item.quantity - 1,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets
                                                    .symmetric(horizontal: 10),
                                                child: AnimatedSwitcher(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  transitionBuilder:
                                                      (child, anim) =>
                                                          ScaleTransition(
                                                    scale: anim,
                                                    child: child,
                                                  ),
                                                  child: Text(
                                                    '${item.quantity}',
                                                    key: ValueKey(
                                                      item.quantity,
                                                    ),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 13.5,
                                                      color:
                                                          KinovaColors.brown,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              _MiniQty(
                                                icon: Icons.add_rounded,
                                                onTap: () => cart.setItemQuantity(
                                                  item,
                                                  item.quantity + 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          formatMoney(item.lineTotal),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: KinovaColors.brown,
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
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  decoration: BoxDecoration(
                    color: KinovaColors.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: KinovaColors.brown.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -6),
                      ),
                    ],
                    border: Border.all(
                      color: KinovaColors.gold.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        _RowPrice(label: 'Sous-total', value: cart.subtotal),
                        _RowPrice(
                          label: 'Livraison',
                          value: cart.shipping,
                          freeLabel: cart.shipping == 0 ? 'Offerte' : null,
                        ),
                        const Divider(height: 22, color: KinovaColors.sand),
                        _RowPrice(
                          label: 'Total TTC',
                          value: cart.total,
                          bold: true,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            final auth = context.read<AuthController>();
                            if (!auth.isLoggedIn) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  duration: Duration(seconds: 2),
                                  backgroundColor: KinovaColors.brown,
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    'Veuillez vous connecter pour passer votre commande',
                                    style: TextStyle(color: KinovaColors.cream),
                                  ),
                                ),
                              );
                              final loggedIn = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => const AuthScreen(),
                                ),
                              );
                              if (loggedIn == true && context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CheckoutScreen(),
                                  ),
                                );
                              }
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CheckoutScreen(),
                                ),
                              );
                            }
                          },
                          child: const Text('PASSER LA COMMANDE'),
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

class _RowPrice extends StatelessWidget {
  const _RowPrice({
    required this.label,
    required this.value,
    this.bold = false,
    this.freeLabel,
  });

  final String label;
  final double value;
  final bool bold;
  final String? freeLabel;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(
            freeLabel ?? formatMoney(value),
            style: style?.copyWith(
              color: KinovaColors.brown,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniQty extends StatelessWidget {
  const _MiniQty({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: KinovaColors.brown),
        ),
      ),
    );
  }
}
