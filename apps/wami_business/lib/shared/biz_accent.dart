import 'package:flutter/material.dart';
import 'package:wami_core/wami_core.dart';

/// Accent de WAMI Business (turquoise), distinct de Pro (bleu) et du client (orange).
abstract final class BizAccent {
  static const glow = WamiColors.glowBus;
  static const soft = Color(0xFF9FE6DF);
}

/// Feuille basse WAMI (actions, formulaires courts). Renvoie la valeur passée à `Navigator.pop`.
Future<T?> showBizSheet<T>(BuildContext context, {required List<Widget> Function(BuildContext) children}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: WamiSheet(children: children(sheetContext)),
    ),
  );
}
