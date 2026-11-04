import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/pro_accent.dart';
import '../../domain/entities/referral.dart';
import '../cubit/referrals_cubit.dart';

/// Parrainage : mon code à partager, mes filleuls, et mon propre parrainage.
class ReferralsPage extends StatefulWidget {
  const ReferralsPage({super.key});

  @override
  State<ReferralsPage> createState() => _ReferralsPageState();
}

class _ReferralsPageState extends State<ReferralsPage> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocConsumer<ReferralsCubit, ReferralsState>(
      listenWhen: (a, b) => (b.failure != null && a.failure != b.failure) || (b.notice != null && a.notice != b.notice),
      listener: (context, s) => showWamiMessage(context, s.failure?.message ?? s.notice!),
      builder: (context, s) {
        final d = s.data;
        return WamiScreen(
          title: 'Parrainage',
          glow: ProAccent.glow,
          body: d == null
              ? const SizedBox(height: 300, child: WamiLoading())
              : Gap(
                  children: [
                    GlassCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SectionLabel('Mon code'),
                        Row(children: [
                          Expanded(child: NumberText(d.myCode.isEmpty ? '—' : d.myCode, size: 22)),
                          IconButton(
                            tooltip: 'Copier',
                            icon: const Icon(Icons.copy_rounded),
                            onPressed: d.myCode.isEmpty
                                ? null
                                : () {
                                    Clipboard.setData(ClipboardData(text: d.myCode));
                                    showWamiMessage(context, 'Code copié.');
                                  },
                          ),
                        ]),
                        Text('${d.totalValidated} validé(s) · ${d.totalPending} en attente', style: t.bodySmall),
                      ]),
                    ),
                    if (d.mine != null)
                      GlassCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Text('Vous avez été parrainé (${d.mine!.code})', style: t.titleSmall),
                          Text('${d.mine!.status.label} · récompense : ${Fmt.fcfa(d.mine!.myReward)}', style: t.bodySmall),
                          if (d.mine!.status == ReferralStatus.pending)
                            TextButton(onPressed: s.busy ? null : context.read<ReferralsCubit>().validate, child: const Text('Valider mon parrainage')),
                        ]),
                      )
                    else ...[
                      const SectionLabel('J’ai un code de parrainage'),
                      Row(children: [
                        Expanded(child: WamiTextField(hint: 'Code', controller: _code)),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: s.busy ? null : () => context.read<ReferralsCubit>().apply(_code.text),
                          child: const Text('Appliquer'),
                        ),
                      ]),
                      Text('Le code se saisit de préférence à l’inscription.', style: t.bodySmall?.copyWith(fontSize: 11.5)),
                    ],
                    const SectionLabel('Mes filleuls'),
                    if (d.items.isEmpty)
                      Text('Personne n’a encore utilisé votre code.', style: t.bodySmall)
                    else
                      GlassGroup(children: [
                        for (final r in d.items)
                          ListRow(
                            title: r.name,
                            subtitle: '${Fmt.relativeDay(r.createdAt)} · ${r.status.label}',
                            icon: Icons.person_add_alt_1_rounded,
                            iconColor: r.status == ReferralStatus.validated ? WamiColors.success : null,
                            trailing: NumberText(Fmt.fcfa(r.reward), size: 14),
                          ),
                      ]),
                  ],
                ),
        );
      },
    );
  }
}
