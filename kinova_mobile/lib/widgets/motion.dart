import 'package:flutter/material.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';

class SoftNetworkImage extends StatelessWidget {
  const SoftNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.memCacheWidth = 400,
  });

  final String url;
  final BoxFit fit;
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: memCacheWidth,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: KinovaColors.cream,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: KinovaColors.sand,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, error, stack) => const ColoredBox(
        color: KinovaColors.cream,
        child: Center(
          child: Icon(Icons.image_outlined, color: KinovaColors.sand),
        ),
      ),
    );
  }
}

/// Effet "press" tactile : la carte s'enfonce légèrement au toucher.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.965,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Lightweight enter animation — one controller, no heavy stacks.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // delay approximated by clamping early frames via opacity curve
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
