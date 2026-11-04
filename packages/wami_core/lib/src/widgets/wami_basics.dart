import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../domain/service_art.dart';
import '../theme/wami_colors.dart';
import '../theme/wami_palette.dart';
import '../theme/wami_tokens.dart';
import '../theme/wami_typography.dart';

/// Sur-titre de section en capitales espacées.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelSmall);
    if (trailing == null) return label;
    return Row(children: [Expanded(child: label), trailing!]);
  }
}

/// Illustration 3D d'un service (design system, niveau 1 de l'iconographie).
class ServiceIllustration extends StatelessWidget {
  const ServiceIllustration(this.art, {super.key, this.size = 64});
  final ServiceArt art;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(art.assetPath, package: 'wami_core', width: size, height: size, semanticsLabel: art.label);
  }
}

/// Logo WAMI (piste A « La route »).
class WamiLogo extends StatelessWidget {
  const WamiLogo({super.key, this.height = 26, this.symbolOnly = false});
  final double height;
  final bool symbolOnly;

  @override
  Widget build(BuildContext context) {
    final asset = symbolOnly
        ? 'assets/logos/symbole-orange.svg'
        : (context.isDark ? 'assets/logos/logo-horizontal-sur-nuit.svg' : 'assets/logos/logo-horizontal.svg');
    return SvgPicture.asset(asset, package: 'wami_core', height: height, semanticsLabel: 'WAMI');
  }
}

/// Prix ou chiffre mis en avant (Unbounded).
class NumberText extends StatelessWidget {
  const NumberText(this.text, {super.key, this.size = 15, this.color, this.glow = false});
  final String text;
  final double size;
  final Color? color;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: WamiTypography.number(size, color: color ?? context.wami.ink).copyWith(
        shadows: glow ? [Shadow(color: WamiColors.orange.withValues(alpha: 0.45), blurRadius: 30)] : null,
      ),
    );
  }
}

/// Pastille d'information (« Meilleur choix », « Confirmé »…).
class WamiTag extends StatelessWidget {
  const WamiTag(this.text, {super.key, this.tint});
  final String text;

  /// `null` : dégradé orange, texte blanc. Sinon : pastille teintée.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final tinted = tint != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: tinted ? null : const LinearGradient(colors: [WamiColors.orangeLight, WamiColors.orangeDeep]),
        color: tinted ? tint!.withValues(alpha: 0.16) : null,
        borderRadius: BorderRadius.circular(WamiRadius.pill),
        border: tinted ? Border.all(color: tint!.withValues(alpha: 0.45)) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: tinted ? Color.lerp(tint, WamiColors.white, context.isDark ? 0.55 : 0)! : WamiColors.white,
        ),
      ),
    );
  }
}

/// Note sur 5 avec étoile.
class RatingText extends StatelessWidget {
  const RatingText(this.rating, {super.key, this.size = 13});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size + 2, color: WamiColors.star),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1).replaceAll('.', ','),
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: WamiColors.star),
        ),
      ],
    );
  }
}

/// Avatar à initiales, cerclé d'orange.
class WamiAvatar extends StatelessWidget {
  const WamiAvatar({super.key, required this.initials, this.size = 44, this.gradient});
  final String initials;
  final double size;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [WamiColors.nuitLight, WamiColors.nuit],
            ),
        boxShadow: [
          BoxShadow(color: context.wami.surface, spreadRadius: 2),
          BoxShadow(color: WamiColors.orangeLight.withValues(alpha: 0.7), spreadRadius: 4),
        ],
      ),
      child: Text(
        initials,
        style: TextStyle(color: WamiColors.white, fontWeight: FontWeight.w700, fontSize: size * 0.32),
      ),
    );
  }
}

/// Carré d'icône teinté pour les listes.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.color, this.size = 38});
  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.wami.orangeStrong;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(icon, size: 20, color: c),
    );
  }
}
