import 'package:flutter/material.dart';

import '../theme/wami_palette.dart';

/// Champ de saisie WAMI : verre, icône à gauche, bord orange au focus.
class WamiTextField extends StatelessWidget {
  const WamiTextField({
    super.key,
    required this.hint,
    this.controller,
    this.icon,
    this.prefixText,
    this.suffix,
    this.keyboardType,
    this.onChanged,
    this.autofocus = false,
    this.label,
    this.initialValue,
  });

  final String hint;
  final TextEditingController? controller;
  final IconData? icon;
  final String? prefixText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final String? label;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    final p = context.wami;
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      autofocus: autofocus,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14, color: p.ink, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        labelStyle: TextStyle(color: p.inkMuted, fontSize: 12),
        prefixIcon: icon == null ? null : Icon(icon, size: 20, color: p.inkMuted),
        prefixText: prefixText,
        prefixStyle: TextStyle(color: p.ink, fontWeight: FontWeight.w600, fontSize: 14),
        suffixIcon: suffix,
      ),
    );
  }
}

/// Bloc « départ → arrivée » avec ligne de trajet lumineuse.
class RouteFields extends StatelessWidget {
  const RouteFields({
    super.key,
    required this.fromHint,
    required this.toHint,
    this.fromController,
    this.toController,
    this.onToChanged,
    this.autofocusTo = false,
  });

  final String fromHint;
  final String toHint;
  final TextEditingController? fromController;
  final TextEditingController? toController;
  final ValueChanged<String>? onToChanged;
  final bool autofocusTo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 110,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66FFFFFF), Color(0xFFFF7A2E)],
                    ),
                  ),
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7A2E),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x88FF7A2E), blurRadius: 12)],
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              WamiTextField(hint: fromHint, controller: fromController),
              const SizedBox(height: 8),
              WamiTextField(
                hint: toHint,
                controller: toController,
                onChanged: onToChanged,
                autofocus: autofocusTo,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
