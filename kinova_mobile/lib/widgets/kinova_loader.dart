import 'package:flutter/material.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';
import 'package:kinova_mobile/widgets/animated_logo_badge.dart';

/// Loader signature KINOVA : logo pulsant entouré de l'anneau doré
/// rotatif, halo lumineux et message avec points animés.
class KinovaLoader extends StatefulWidget {
  const KinovaLoader({
    super.key,
    this.size = 86,
    this.message = 'Chargement',
    this.compact = false,
  });

  final double size;
  final String? message;

  /// Version réduite sans halo, pour les petits espaces.
  final bool compact;

  @override
  State<KinovaLoader> createState() => _KinovaLoaderState();
}

class _KinovaLoaderState extends State<KinovaLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Transform.scale(
          scale: 0.96 + t * 0.06,
          child: Container(
            decoration: widget.compact
                ? null
                : BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37)
                            .withValues(alpha: 0.12 + t * 0.18),
                        blurRadius: 26 + t * 14,
                        spreadRadius: 2 + t * 4,
                      ),
                    ],
                  ),
            child: child,
          ),
        );
      },
      child: AnimatedLogoBadge(size: widget.size),
    );

    if (widget.message == null) return Center(child: badge);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          SizedBox(height: widget.compact ? 12 : 18),
          _AnimatedDotsLabel(text: widget.message!),
        ],
      ),
    );
  }
}

/// Texte suivi de trois points qui apparaissent en boucle.
class _AnimatedDotsLabel extends StatefulWidget {
  const _AnimatedDotsLabel({required this.text});

  final String text;

  @override
  State<_AnimatedDotsLabel> createState() => _AnimatedDotsLabelState();
}

class _AnimatedDotsLabelState extends State<_AnimatedDotsLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = (_controller.value * 3).floor() % 3;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.text.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
                color: KinovaColors.mutedBrown.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(width: 3),
            for (var i = 0; i < 3; i++)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: i <= phase ? 1 : 0.15,
                child: const Text(
                  '.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: KinovaColors.gold,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
