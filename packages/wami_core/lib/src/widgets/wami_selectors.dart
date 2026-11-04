import 'package:flutter/material.dart';

import '../theme/wami_colors.dart';
import '../theme/wami_palette.dart';
import '../theme/wami_tokens.dart';
import '../theme/wami_typography.dart';

/// Puce sélectionnable (tri, filtres, dates, montants).
class WamiChip extends StatelessWidget {
  const WamiChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.expand = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.wami;
    final fg = selected ? (context.isDark ? WamiColors.orangePeach : WamiColors.orangeDeep) : p.ink;
    final chip = Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: WamiMotion.fast,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: selected ? WamiColors.orange.withValues(alpha: 0.18) : p.glass,
          borderRadius: BorderRadius.circular(WamiRadius.pill),
          border: Border.all(
            color: selected ? WamiColors.orangeLight.withValues(alpha: 0.65) : p.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: selected ? fg : p.orangeStrong),
              const SizedBox(width: 6),
            ],
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
    final tappable = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WamiRadius.pill),
      child: chip,
    );
    return expand ? Expanded(child: tappable) : tappable;
  }
}

/// Rangée de puces défilante horizontalement, marges d'écran incluses.
class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: WamiSpace.screen),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

/// Sélecteur segmenté (Envoyer / Faire récupérer, Hôtel / Chambre / Appartement…).
class WamiSegmented<T> extends StatelessWidget {
  const WamiSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.wami;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.glassBorder),
      ),
      child: Row(
        children: [
          for (final (v, label) in options)
            Expanded(
              child: Semantics(
                selected: v == value,
                button: true,
                child: GestureDetector(
                  onTap: () => onChanged(v),
                  child: AnimatedContainer(
                    duration: WamiMotion.base,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: v == value
                          ? LinearGradient(colors: [
                              WamiColors.orangeLight.withValues(alpha: 0.35),
                              WamiColors.orangeDeep.withValues(alpha: 0.35),
                            ])
                          : null,
                      border: v == value
                          ? Border.all(color: WamiColors.orangeLight.withValues(alpha: 0.6))
                          : null,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: v == value ? (context.isDark ? WamiColors.white : WamiColors.orangeDeep) : p.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Interrupteur WAMI (dégradé orange quand actif).
class WamiToggle extends StatelessWidget {
  const WamiToggle({super.key, required this.value, required this.onChanged, required this.label});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: WamiMotion.base,
          width: 46,
          height: 28,
          padding: const EdgeInsets.all(4),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: value ? WamiEffects.ctaGradient : null,
            color: value ? null : context.wami.ink.withValues(alpha: 0.14),
            boxShadow: value ? [BoxShadow(color: WamiColors.orange.withValues(alpha: 0.5), blurRadius: 12)] : null,
          ),
          child: const SizedBox.square(
            dimension: 20,
            child: DecoratedBox(decoration: BoxDecoration(color: WamiColors.white, shape: BoxShape.circle)),
          ),
        ),
      ),
    );
  }
}

/// Ligne « libellé + description + interrupteur ».
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleSmall),
                if (subtitle != null) Text(subtitle!, style: t.bodySmall?.copyWith(fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          WamiToggle(value: value, onChanged: onChanged, label: title),
        ],
      ),
    );
  }
}

/// Option sélectionnable façon bouton radio (moyen de paiement, chambre, source…).
class WamiOptionTile extends StatelessWidget {
  const WamiOptionTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.trailing,
    this.showRadio = true,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;
  final bool showRadio;

  @override
  Widget build(BuildContext context) {
    final p = context.wami;
    final t = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: WamiMotion.base,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: selected ? WamiEffects.selectedGradient : null,
            color: selected ? null : p.glass,
            border: Border.all(
              color: selected ? WamiColors.orangeLight.withValues(alpha: 0.85) : p.glassBorder,
            ),
            boxShadow: selected ? [BoxShadow(color: WamiColors.orange.withValues(alpha: 0.16), blurRadius: 22)] : null,
          ),
          child: Row(
            children: [
              if (showRadio) ...[
                AnimatedContainer(
                  duration: WamiMotion.base,
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? WamiColors.orange : p.ink.withValues(alpha: 0.3),
                      width: selected ? 6 : 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.titleSmall),
                    if (subtitle != null) Text(subtitle!, style: t.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Compteur « − n + » (voyageurs, personnes).
class CounterStepper extends StatelessWidget {
  const CounterStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.min = 1,
    this.max = 6,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String label;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    Widget btn(String symbol, String tip, VoidCallback? onTap) => Tooltip(
          message: tip,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: context.wami.glass,
                border: Border.all(color: context.wami.glassBorder),
              ),
              child: Text(symbol, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn('−', 'Retirer : $label', value > min ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: WamiTypography.display, fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        btn('+', 'Ajouter : $label', value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }
}
