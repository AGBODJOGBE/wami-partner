import 'package:flutter/material.dart';
import 'package:wami_core/wami_core.dart';

import 'location_service.dart';

/// Écran d'explication affiché AVANT la demande système de localisation en arrière-plan.
/// Google Play l'exige (« prominent disclosure ») et Apple le vérifie à la revue.
abstract final class BackgroundLocationDisclosure {
  /// Explique l'usage, puis demande la permission si l'utilisateur accepte.
  /// Ne bloque jamais la mise en ligne : un refus laisse le suivi tant que l'app est ouverte.
  static Future<void> show(BuildContext context) async {
    if (sl<AppConfig>().useFakeBackend) return;
    final location = sl<LocationService>();
    if (await location.hasBackgroundPermission()) return;
    if (!context.mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Votre position, même écran éteint'),
        content: const Text(
          'WAMI Pro utilise votre position même lorsque l’app est fermée ou l’écran éteint, '
          'pour vous proposer des missions proches et suivre vos courses en cours.\n\n'
          'Elle n’est utilisée que lorsque vous êtes en ligne ou en mission.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Pas maintenant')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continuer')),
        ],
      ),
    );
    if (accepted == true) await location.requestBackgroundPermission();
  }
}
