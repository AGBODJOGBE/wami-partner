import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../error/failures.dart';
import '../theme/wami_colors.dart';
import '../theme/wami_palette.dart';
import '../theme/wami_tokens.dart';
import 'wami_background.dart';
import 'wami_buttons.dart';

/// Écran standard WAMI : fond futuriste, en-tête (retour + titre), contenu,
/// et zone d'action fixe en bas (bouton principal).
class WamiScreen extends StatelessWidget {
  /// Route de repli quand il n'y a rien à dépiler (à fixer au démarrage de chaque app).
  static String homeRoute = '/home';

  const WamiScreen({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.onBack,
    this.showBack = true,
    this.actions = const [],
    this.bottom,
    this.glow = WamiColors.glowMobilite,
    this.scrollable = true,
    this.padding = const EdgeInsets.fromLTRB(WamiSpace.screen, 8, WamiSpace.screen, 16),
  });

  final Widget body;
  final String? title;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool showBack;
  final List<Widget> actions;
  final Widget? bottom;
  final Color glow;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(WamiSpace.screen, 12, WamiSpace.screen, 4),
      child: Row(
        children: [
          if (showBack) ...[
            WamiIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: 'Retour',
              onPressed: onBack ?? () => context.canPop() ? context.pop() : context.go(homeRoute),
            ),
            const SizedBox(width: 12),
          ],
          if (title != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title!, style: subtitle == null ? t.headlineSmall : t.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (subtitle != null) Text(subtitle!, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            )
          else
            const Spacer(),
          ...actions,
        ],
      ),
    );

    final content = Padding(padding: padding, child: body);

    return Scaffold(
      backgroundColor: context.wami.surface,
      body: WamiBackground(
        glow: glow,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              header,
              Expanded(child: scrollable ? SingleChildScrollView(child: content) : content),
              if (bottom != null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(WamiSpace.screen, 4, WamiSpace.screen, 16),
                    child: bottom,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Colonne avec espacement régulier entre les enfants.
class Gap extends StatelessWidget {
  const Gap({super.key, required this.children, this.gap = 14, this.crossAxisAlignment = CrossAxisAlignment.stretch});
  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) out.add(SizedBox(height: gap));
      out.add(children[i]);
    }
    return Column(crossAxisAlignment: crossAxisAlignment, mainAxisSize: MainAxisSize.min, children: out);
  }
}

/// Chargement plein écran.
class WamiLoading extends StatelessWidget {
  const WamiLoading({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: WamiColors.orangeLight),
          ),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(label!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Erreur avec bouton « Réessayer ».
class WamiErrorView extends StatelessWidget {
  const WamiErrorView({super.key, required this.failure, this.onRetry});
  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WamiSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 36, color: context.wami.danger),
            const SizedBox(height: 12),
            Text(failure.message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              WamiGhostButton(label: 'Réessayer', icon: Icons.refresh_rounded, onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}

void showWamiMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Écran de réussite (réservation, transfert, recharge…).
class WamiSuccessView extends StatelessWidget {
  const WamiSuccessView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.children = const [],
    this.positive = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> children;

  /// `true` : vert (livré, envoyé). `false` : orange (réservé, payé).
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final colors = positive
        ? const [Color(0xFF7BE3AE), WamiColors.successDeep]
        : const [Color(0xFFFF9A5A), WamiColors.orangeDeep];
    final glow = positive ? WamiColors.success : WamiColors.orange;
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(center: const Alignment(-0.4, -0.5), colors: colors),
            boxShadow: [
              BoxShadow(color: glow.withValues(alpha: 0.12), spreadRadius: 12),
              BoxShadow(color: glow.withValues(alpha: 0.5), blurRadius: 60),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 22),
        Text(title, style: t.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(message, style: t.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 22),
        ...children,
      ],
    );
  }
}
