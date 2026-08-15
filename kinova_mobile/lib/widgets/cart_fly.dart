import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/motion.dart';

/// Animation « vol vers le panier » : une vignette du produit s'élève
/// depuis sa carte puis retombe en arc de cercle dans le panier.
class CartFly {
  CartFly._();

  /// Clé posée sur le bouton panier de la barre de navigation.
  static final GlobalKey cartKey = GlobalKey();

  /// Incrémenté à chaque atterrissage pour faire rebondir le panier.
  static final ValueNotifier<int> bumps = ValueNotifier<int>(0);

  /// Lance l'animation depuis le widget associé à [from].
  static void fly(BuildContext from, String imageUrl) {
    final box = from.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;

    final overlay = Overlay.of(from, rootOverlay: true);
    final start = box.localToGlobal(box.size.center(Offset.zero));

    Offset end;
    final cartContext = cartKey.currentContext;
    if (cartContext != null) {
      final cartBox = cartContext.findRenderObject() as RenderBox;
      end = cartBox.localToGlobal(cartBox.size.center(Offset.zero));
    } else {
      final screen = MediaQuery.of(from).size;
      end = Offset(screen.width / 2, screen.height - 70);
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FlyingProduct(
        start: start,
        end: end,
        imageUrl: imageUrl,
        onDone: () {
          entry.remove();
          bumps.value++;
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _FlyingProduct extends StatefulWidget {
  const _FlyingProduct({
    required this.start,
    required this.end,
    required this.imageUrl,
    required this.onDone,
  });

  final Offset start;
  final Offset end;
  final String imageUrl;
  final VoidCallback onDone;

  @override
  State<_FlyingProduct> createState() => _FlyingProductState();
}

class _FlyingProductState extends State<_FlyingProduct>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _size = 58.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _position(double t) {
    // Courbe de Bézier quadratique : monte au-dessus du départ puis
    // retombe vers le panier.
    final control = Offset(
      (widget.start.dx + widget.end.dx) / 2,
      math.min(widget.start.dy, widget.end.dy) - 130,
    );
    final u = 1 - t;
    return Offset(
      u * u * widget.start.dx + 2 * u * t * control.dx + t * t * widget.end.dx,
      u * u * widget.start.dy + 2 * u * t * control.dy + t * t * widget.end.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOutCubic.transform(_controller.value);
          final pos = _position(t);
          // Grossit légèrement au décollage puis rétrécit en tombant.
          final scale = t < 0.25
              ? 1.0 + t * 0.5
              : 1.125 - (t - 0.25) / 0.75 * 0.85;
          final opacity = t > 0.88 ? (1 - t) / 0.12 : 1.0;

          return Stack(
            children: [
              Positioned(
                left: pos.dx - _size / 2,
                top: pos.dy - _size / 2,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(scale: scale, child: child),
                ),
              ),
            ],
          );
        },
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: KinovaColors.gold, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: KinovaColors.brown.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: KinovaColors.goldRich.withValues(alpha: 0.35),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: widget.imageUrl.isEmpty
                ? const ColoredBox(
                    color: KinovaColors.surfaceMuted,
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: KinovaColors.gold,
                    ),
                  )
                : SoftNetworkImage(url: widget.imageUrl, memCacheWidth: 160),
          ),
        ),
      ),
    );
  }
}
