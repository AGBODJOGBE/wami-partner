import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/wami_colors.dart';
import '../theme/wami_palette.dart';
import '../theme/wami_tokens.dart';

/// Point « en direct » qui pulse.
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, this.color = WamiColors.orangeLight});
  final Color color;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.35).animate(_c),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(color: widget.color.withValues(alpha: 0.25), spreadRadius: 3),
            BoxShadow(color: widget.color, blurRadius: 10),
          ],
        ),
      ),
    );
  }
}

/// Pastille flottante en verre (statut de course, ETA…).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.child, this.onTap, this.live = false});
  final Widget child;
  final VoidCallback? onTap;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(WamiRadius.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: context.isDark ? const Color(0xD609101F) : const Color(0xE6FFFFFF),
          shape: StadiumBorder(side: BorderSide(color: context.wami.glassBorder)),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (live) ...[const LiveDot(), const SizedBox(width: 8)],
                  DefaultTextStyle.merge(
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Feuille basse flottante avec poignée (au-dessus d'une carte).
class WamiSheet extends StatelessWidget {
  const WamiSheet({super.key, required this.children, this.padding});
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final p = context.wami;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(WamiRadius.sheet)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.fromLTRB(18, 12, 18, 20),
          decoration: BoxDecoration(
            color: p.sheet,
            border: Border(top: BorderSide(color: p.glassBorder)),
            boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 40, offset: Offset(0, -20))],
          ),
          child: SafeArea(
            top: false,
            // Défile si le contenu dépasse la hauteur de l'écran (petits téléphones).
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: p.ink.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                ..._spaced(children),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _spaced(List<Widget> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) out.add(const SizedBox(height: 12));
      out.add(items[i]);
    }
    return out;
  }
}
