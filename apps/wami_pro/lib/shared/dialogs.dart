import 'package:flutter/material.dart';

/// Demande un motif en texte libre. Renvoie `null` si l'utilisateur renonce.
Future<String?> askReason(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmLabel,
  List<String> suggestions = const [],
  bool required = false,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (suggestions.isNotEmpty)
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (final s in suggestions)
                  ActionChip(label: Text(s), onPressed: () => setState(() => controller.text = s)),
              ]),
            TextField(controller: controller, decoration: InputDecoration(hintText: hint), onChanged: (_) => setState(() {})),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Retour')),
          FilledButton(
            onPressed: required && controller.text.trim().length < 3 ? null : () => Navigator.pop(context, controller.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
}

/// Confirmation simple (oui / non).
Future<bool> confirm(BuildContext context, {required String title, required String message, required String confirmLabel}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Retour')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(confirmLabel)),
      ],
    ),
  );
  return ok ?? false;
}
