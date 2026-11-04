import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/biz_accent.dart';
import '../../../../shared/data_state.dart';
import '../../domain/entities/review.dart';
import '../cubit/reviews_cubit.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key, required this.establishmentId});
  final String establishmentId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReviewsCubit>();
    final t = Theme.of(context).textTheme;
    return BlocConsumer<ReviewsCubit, DataState<ReviewsSummary>>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      builder: (context, s) {
        final d = s.data;
        return WamiScreen(
          title: 'Avis clients',
          subtitle: d == null ? null : '${d.unanswered} sans réponse',
          glow: BizAccent.glow,
          body: d == null
              ? (s.status == LoadStatus.failure
                  ? WamiErrorView(failure: s.failure!, onRetry: () => cubit.load(establishmentId))
                  : const SizedBox(height: 300, child: WamiLoading()))
              : Gap(children: [
                  GlassCard(
                    child: Row(children: [
                      Column(children: [
                        NumberText(d.average.toStringAsFixed(1), size: 34, color: WamiColors.star),
                        Text('${d.reviews.length} avis', style: t.bodySmall),
                      ]),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(children: [
                          for (var i = 0; i < 5; i++)
                            Row(children: [
                              SizedBox(width: 16, child: Text('${5 - i}', style: t.bodySmall)),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: d.reviews.isEmpty ? 0 : d.distribution[i] / d.reviews.length,
                                  minHeight: 5,
                                  color: WamiColors.star,
                                  backgroundColor: context.wami.glass,
                                ),
                              ),
                            ]),
                        ]),
                      ),
                    ]),
                  ),
                  for (final r in d.reviews) _ReviewCard(review: r, busy: s.busy),
                ]),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.busy});
  final Review review;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = review;
    return ActionCard(
      hot: !r.answered && r.rating <= 3,
      child: Gap(gap: 8, children: [
        Row(children: [
          WamiAvatar(initials: Fmt.initials(r.author), size: 34),
          const SizedBox(width: 10),
          Expanded(child: Text(r.author, style: t.titleSmall)),
          Text('${'★' * r.rating}${'☆' * (5 - r.rating)}', style: const TextStyle(color: WamiColors.star)),
        ]),
        Text(r.text, style: t.bodyMedium),
        Text(Fmt.relativeDay(r.date), style: t.bodySmall),
        if (r.reply != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: context.wami.glass, borderRadius: BorderRadius.circular(12)),
            child: Text('Votre réponse : ${r.reply}', style: t.bodySmall),
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: busy ? null : () => _reply(context),
              icon: const Icon(Icons.reply_rounded),
              label: const Text('Répondre'),
            ),
          ),
      ]),
    );
  }

  Future<void> _reply(BuildContext context) async {
    final cubit = context.read<ReviewsCubit>();
    final text = await showBizSheet<String>(context, children: (_) => [_ReplyEditor(author: review.author)]);
    if (text != null) await cubit.reply(review, text);
  }
}

/// Possède son contrôleur : il vit aussi longtemps que la feuille, animation de fermeture comprise.
class _ReplyEditor extends StatefulWidget {
  const _ReplyEditor({required this.author});
  final String author;

  @override
  State<_ReplyEditor> createState() => _ReplyEditorState();
}

class _ReplyEditorState extends State<_ReplyEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Gap(children: [
      Text('Répondre à ${widget.author}', style: t.titleMedium),
      Text('Votre réponse est publique.', style: t.bodySmall),
      TextField(
        controller: _controller,
        maxLines: 4,
        maxLength: ReplyRules.maxLength,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Merci pour votre retour…'),
      ),
      WamiPrimaryButton(label: 'Publier', onPressed: () => Navigator.pop(context, _controller.text)),
    ]);
  }
}
