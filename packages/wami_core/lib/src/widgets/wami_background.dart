import 'package:flutter/material.dart';

import '../theme/wami_colors.dart';
import '../theme/wami_palette.dart';

/// Fond futuriste : nuit profonde + deux lueurs radiales (haut droite, bas gauche).
/// La lueur principale prend la couleur de l'univers du service.
class WamiBackground extends StatelessWidget {
  const WamiBackground({
    super.key,
    required this.child,
    this.glow = WamiColors.glowMobilite,
    this.secondaryGlow = WamiColors.glowLivraison,
  });

  final Widget child;
  final Color glow;
  final Color secondaryGlow;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return DecoratedBox(
      decoration: BoxDecoration(color: context.wami.surface),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.1, -1.1),
                  radius: 1.25,
                  colors: [glow.withValues(alpha: dark ? 0.28 : 0.14), glow.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-1.2, 1.1),
                  radius: 1.0,
                  colors: [
                    secondaryGlow.withValues(alpha: dark ? 0.22 : 0.10),
                    secondaryGlow.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
