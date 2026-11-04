import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wami_core/wami_core.dart';

/// Appel et SMS vers le client via l'application Téléphone / Messages de l'appareil.
/// Aucune permission n'est requise (`tel:` et `sms:` ouvrent l'app système).
abstract final class Contact {
  static Future<void> call(BuildContext context, String? phone) => _open(context, phone, 'tel');

  static Future<void> message(BuildContext context, String? phone) => _open(context, phone, 'sms');

  static Future<void> _open(BuildContext context, String? phone, String scheme) async {
    final number = phone?.replaceAll(RegExp(r'[^\d+]'), '') ?? '';
    if (number.isEmpty) {
      showWamiMessage(context, 'Numéro du client indisponible.');
      return;
    }
    var ok = false;
    try {
      ok = await launchUrl(Uri(scheme: scheme, path: number));
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) showWamiMessage(context, 'Impossible d’ouvrir ${scheme == 'tel' ? 'le téléphone' : 'les messages'}.');
  }
}
