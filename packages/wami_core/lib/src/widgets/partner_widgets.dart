import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../theme/wami_colors.dart';
import '../theme/wami_palette.dart';
import '../theme/wami_tokens.dart';
import '../theme/wami_typography.dart';
import 'glass_card.dart';

/// Anneau de compte à rebours (délai pour accepter une mission ou une commande).
class CountdownRing extends StatelessWidget {
  const CountdownRing({super.key, required this.remaining, required this.total, this.size = 96});
  final int remaining;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0);
    return Semantics(
      label: '$remaining secondes restantes',
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(ratio: ratio, track: context.wami.ink.withValues(alpha: 0.1)),
          child: Center(child: Text('$remaining', style: WamiTypography.number(size * 0.27, color: context.wami.ink))),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.ratio, required this.track});
  final double ratio;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(6);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, p..color = track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * ratio, false, p..color = WamiColors.orangeLight);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.ratio != ratio || old.track != track;
}

/// Indicateur chiffré compact.
class KpiTile extends StatelessWidget {
  const KpiTile({super.key, required this.value, required this.label, this.color});
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.wami;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.glass,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(child: Text(value, style: WamiTypography.number(17, color: color ?? p.ink))),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: p.inkMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Rangée de KPI de largeur égale.
class KpiRow extends StatelessWidget {
  const KpiRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

/// Histogramme simple (gains par jour, ventes par semaine).
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.highlight,
    this.color = WamiColors.orangeLight,
    this.height = 120,
  });

  final List<num> values;
  final List<String> labels;
  final int? highlight;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final max = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    final p = context.wami;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: max == 0 ? 0 : (values[i] / max).clamp(0.04, 1.0).toDouble(),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(7), bottom: Radius.circular(3)),
                            color: i == highlight ? null : p.ink.withValues(alpha: 0.12),
                            gradient: i == highlight
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [color, Color.lerp(color, Colors.black, 0.35)!],
                                  )
                                : null,
                            boxShadow: i == highlight ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 14)] : null,
                          ),
                          child: const SizedBox(width: double.infinity),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(labels[i], style: TextStyle(fontSize: 10.5, color: p.inkMuted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ligne « libellé ……… valeur » (récapitulatifs, relevés).
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.valueColor, this.strong = false});
  final String label;
  final String value;
  final Color? valueColor;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(label, style: strong ? t.titleSmall : t.bodySmall?.copyWith(fontSize: 13))),
          Text(
            value,
            style: strong
                ? WamiTypography.number(17, color: valueColor ?? context.wami.ink)
                : t.labelLarge?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

/// Ligne de liste avec icône teintée.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.onTap,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = iconColor ?? context.wami.orangeStrong;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)]
            else if (icon != null) ...[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, size: 20, color: c),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleSmall),
                  if (subtitle != null) Text(subtitle!, style: t.bodySmall?.copyWith(fontSize: 11.5)),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!]
            else if (onTap != null) Icon(Icons.chevron_right_rounded, color: context.wami.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// Saisie d'un code à 4 chiffres (code client, code de remise, billet).
class CodeInput extends StatefulWidget {
  const CodeInput({super.key, required this.onChanged, this.length = 4, this.error = false});
  final ValueChanged<String> onChanged;
  final int length;
  final bool error;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.wami;
    final text = _controller.text;
    return GestureDetector(
      onTap: _focus.requestFocus,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: widget.length,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) {
                  setState(() {});
                  widget.onChanged(v);
                },
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.length; i++)
                // Flexible : 6 cases tiennent aussi sur un écran de 360 px.
                Flexible(
                  child: Container(
                  constraints: const BoxConstraints(maxWidth: 52),
                  height: 58,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.glass,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.error
                          ? p.danger
                          : (i == text.length ? WamiColors.orangeLight : p.glassBorder),
                      width: i == text.length ? 1.6 : 1,
                    ),
                    boxShadow: i < text.length ? [BoxShadow(color: WamiColors.orange.withValues(alpha: 0.2), blurRadius: 14)] : null,
                  ),
                  child: Text(i < text.length ? text[i] : '', style: WamiTypography.number(22, color: p.ink)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Grand bouton rond « En ligne / Hors ligne ».
class PowerButton extends StatelessWidget {
  const PowerButton({super.key, required this.online, required this.onTap});
  final bool online;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = online
        ? const [Color(0xFF5FD69A), WamiColors.successDeep]
        : const [Color(0xFFFF9A5A), WamiColors.orangeDeep];
    final glow = online ? WamiColors.success : WamiColors.orange;
    return Semantics(
      button: true,
      toggled: online,
      label: online ? 'En ligne, toucher pour passer hors ligne' : 'Hors ligne, toucher pour passer en ligne',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: WamiMotion.slow,
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(center: const Alignment(-0.4, -0.5), colors: colors),
            boxShadow: [
              BoxShadow(color: glow.withValues(alpha: 0.14), spreadRadius: 10),
              BoxShadow(color: glow.withValues(alpha: 0.06), spreadRadius: 22),
              BoxShadow(color: glow.withValues(alpha: 0.55), blurRadius: 50),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(online ? 'EN LIGNE' : 'PASSER\nEN LIGNE',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.8)),
              if (online)
                const Text('Toucher pour arrêter', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// État vide.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 36, color: context.wami.inkMuted),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Carte « à traiter » avec mise en avant optionnelle.
class ActionCard extends StatelessWidget {
  const ActionCard({super.key, required this.child, this.hot = false, this.onTap});
  final Widget child;
  final bool hot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      borderColor: hot ? WamiColors.orangeLight.withValues(alpha: 0.7) : null,
      gradient: hot
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [WamiColors.orange.withValues(alpha: 0.18), context.wami.glass],
            )
          : null,
      child: child,
    );
  }
}

/// Coque d'onglets avec barre de navigation flottante en verre.
class WamiNavShell extends StatelessWidget {
  const WamiNavShell({super.key, required this.navigationShell, required this.tabs, this.badges = const {}});

  final StatefulNavigationShell navigationShell;
  final List<(IconData, String)> tabs;

  /// Pastille de compteur par index d'onglet.
  final Map<int, int> badges;

  @override
  Widget build(BuildContext context) {
    final p = context.wami;
    final index = navigationShell.currentIndex;
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: context.isDark ? const Color(0xCC0C1527) : const Color(0xE6FFFFFF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: p.glassBorder),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: Semantics(
                        selected: i == index,
                        button: true,
                        label: tabs[i].$2,
                        excludeSemantics: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => navigationShell.goBranch(i, initialLocation: i == index),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AnimatedContainer(
                                    duration: WamiMotion.base,
                                    width: 40,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: i == index ? WamiEffects.ctaGradient : null,
                                      boxShadow: i == index
                                          ? [BoxShadow(color: WamiColors.orange.withValues(alpha: 0.55), blurRadius: 16)]
                                          : null,
                                    ),
                                    child: Icon(tabs[i].$1, size: 20, color: i == index ? Colors.white : p.inkMuted),
                                  ),
                                  if ((badges[i] ?? 0) > 0)
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: WamiColors.orangeLight,
                                          borderRadius: BorderRadius.circular(9),
                                          border: Border.all(color: p.surface, width: 1.5),
                                        ),
                                        child: Text('${badges[i]}',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tabs[i].$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: i == index ? p.ink : p.inkMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
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
