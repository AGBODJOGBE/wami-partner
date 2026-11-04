import 'package:flutter/material.dart';

import '../theme/wami_colors.dart';
import '../theme/wami_palette.dart';
import '../theme/wami_tokens.dart';

/// Bouton principal : dégradé orange, **texte blanc 16 px gras** (règle validée),
/// lueur orange. Désactivé : opacité 40 %, sans lueur.
class WamiPrimaryButton extends StatelessWidget {
  const WamiPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 56,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final double height;
  final bool expand;

  Widget _label() => Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: WamiColors.onPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.16,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final radius = BorderRadius.circular(WamiRadius.cta);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: WamiMotion.fast,
        opacity: enabled || loading ? 1 : 0.4,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: WamiEffects.ctaGradient,
            borderRadius: radius,
            boxShadow: enabled ? WamiEffects.glow() : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: radius,
              child: SizedBox(
                height: height,
                width: expand ? double.infinity : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (loading)
                        const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: WamiColors.white),
                        )
                      else ...[
                        if (icon != null) ...[
                          Icon(icon, color: WamiColors.onPrimary, size: 20),
                          const SizedBox(width: 10),
                        ],
                        // Flexible seulement en pleine largeur : dans une Row non bornée,
                        // un enfant flexible ferait planter la mise en page.
                        if (expand) Flexible(child: _label()) else _label(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton secondaire en verre.
class WamiGhostButton extends StatelessWidget {
  const WamiGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.wami;
    return SizedBox(
      height: height,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 19),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          backgroundColor: p.glass,
          side: BorderSide(color: p.glassBorder),
          textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WamiRadius.cta)),
        ),
      ),
    );
  }
}

/// Bouton carré en verre (retour, filtres, QR…).
class WamiIconButton extends StatelessWidget {
  const WamiIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 42,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.wami;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.isDark ? const Color(0xBF09101F) : p.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size / 3),
          side: BorderSide(color: p.glassBorder),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(size / 3)),
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: 20, color: color ?? p.ink),
          ),
        ),
      ),
    );
  }
}

/// Orbe lumineux orange (appel, action principale ronde).
class GlowOrbButton extends StatelessWidget {
  const GlowOrbButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.4, -0.5),
            colors: [Color(0xFFFF9A5A), WamiColors.orangeMid, Color(0xFFB84200)],
            stops: [0, 0.6, 1],
          ),
          boxShadow: WamiEffects.halo(),
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox.square(
              dimension: size,
              child: Icon(icon, color: WamiColors.white, size: 21),
            ),
          ),
        ),
      ),
    );
  }
}
