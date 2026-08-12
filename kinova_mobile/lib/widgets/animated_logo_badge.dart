import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';

/// Logo circulaire avec anneau animé qui tourne autour.
class AnimatedLogoBadge extends StatefulWidget {
  const AnimatedLogoBadge({
    super.key,
    this.size = 40,
  });

  final double size;

  @override
  State<AnimatedLogoBadge> createState() => _AnimatedLogoBadgeState();
}

class _AnimatedLogoBadgeState extends State<AnimatedLogoBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _OrbitRingPainter(progress: _controller.value),
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(3.5),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  _OrbitRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeW = (size.shortestSide * 0.045).clamp(1.5, 4.5);
    final radius = (size.shortestSide / 2) - (strokeW / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Anneau de fond discret
    final track = Paint()
      ..color = KinovaColors.sand.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW * 0.7;
    canvas.drawCircle(center, radius, track);

    // Arc doré qui fait le tour
    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        transform: GradientRotation(progress * math.pi * 2),
        colors: const [
          Colors.transparent,
          KinovaColors.gold,
          KinovaColors.brown,
          KinovaColors.gold,
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, sweep);

    // Point lumineux en tête de l'arc
    final angle = progress * math.pi * 2 - math.pi / 2;
    final tip = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    final tipRadius = strokeW * 1.1;
    final glow = Paint()
      ..color = KinovaColors.gold.withOpacity(0.9)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeW);
    canvas.drawCircle(tip, tipRadius * 1.4, glow);
    canvas.drawCircle(tip, tipRadius * 0.8, Paint()..color = KinovaColors.cream);
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
