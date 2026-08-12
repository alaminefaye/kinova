import 'package:flutter/material.dart';
import 'package:kinova_mobile/api/api_config.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';

/// Avatar circulaire robuste : URL relative/localhost corrigée,
/// fallback initiale si l’image ne charge pas.
class KinovaAvatar extends StatelessWidget {
  const KinovaAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 26,
  });

  final String name;
  final String? imageUrl;
  final double radius;

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'K';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConfig.resolveMediaUrl(imageUrl);

    return Container(
      width: radius * 2,
      height: radius * 2,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: KinovaColors.gold, width: 1.8),
      ),
      child: ClipOval(
        child: ColoredBox(
          color: KinovaColors.brown,
          child: resolved.isEmpty
              ? _Initial(letter: _initial, radius: radius)
              : Image.network(
                  resolved,
                  fit: BoxFit.cover,
                  width: radius * 2,
                  height: radius * 2,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) =>
                      _Initial(letter: _initial, radius: radius),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: radius * 0.55,
                        height: radius * 0.55,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: KinovaColors.gold,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.letter, required this.radius});

  final String letter;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: KinovaColors.gold,
          fontSize: radius * 0.85,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
