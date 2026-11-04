import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/wami_palette.dart';
import '../theme/wami_tokens.dart';

/// Carte en verre : fond translucide, bord fin, flou d'arrière-plan.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = WamiRadius.card,
    this.onTap,
    this.borderColor,
    this.gradient,
    this.blur = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Gradient? gradient;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final p = context.wami;
    final shape = BorderRadius.circular(radius);
    Widget content = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: shape,
        child: Padding(padding: padding, child: child),
      ),
    );
    content = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? p.glass : null,
        gradient: gradient,
        borderRadius: shape,
        border: Border.all(color: borderColor ?? p.glassBorder),
      ),
      child: content,
    );
    if (!blur) return content;
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: WamiEffects.glassBlur, sigmaY: WamiEffects.glassBlur),
        child: content,
      ),
    );
  }
}

/// Liste de lignes dans une carte en verre, séparées par un filet.
class GlassGroup extends StatelessWidget {
  const GlassGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(indent: 14, endIndent: 14, color: context.wami.glassBorder));
      }
      rows.add(children[i]);
    }
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}
