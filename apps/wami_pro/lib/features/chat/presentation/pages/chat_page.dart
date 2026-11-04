import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/pro_accent.dart';
import '../cubit/chat_cubit.dart';

/// Messages avec le client pendant une mission (course ou livraison).
class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.title});
  final String title;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    context.read<ChatCubit>().send(text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocConsumer<ChatCubit, ChatState>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      builder: (context, s) {
        return WamiScreen(
          title: widget.title,
          glow: ProAccent.glow,
          body: s.loading
              ? const SizedBox(height: 300, child: WamiLoading())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (s.messages.isEmpty) Text('Aucun message pour le moment.', style: t.bodySmall),
                    for (final m in s.messages)
                      Align(
                        alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: m.mine ? WamiColors.orange.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(m.content),
                        ),
                      ),
                    if (s.closed) Padding(padding: const EdgeInsets.only(top: 12), child: Text('La mission est terminée : le chat est fermé.', style: t.bodySmall)),
                  ],
                ),
          bottom: s.closed
              ? null
              : Row(children: [
                  Expanded(child: WamiTextField(hint: 'Votre message', controller: _input)),
                  const SizedBox(width: 8),
                  IconButton(onPressed: () => _submit(context), icon: const Icon(Icons.send_rounded), tooltip: 'Envoyer'),
                ]),
        );
      },
    );
  }
}
