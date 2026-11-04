import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/biz_accent.dart';
import '../../../../shared/business_activity.dart';
import '../../../../shared/routes.dart';
import '../../domain/entities/business.dart';
import '../cubit/onboarding_cubit.dart';

void _showFailure(BuildContext context, OnboardingState s) => showWamiMessage(context, s.failure!.message);

bool _newFailure(OnboardingState a, OnboardingState b) => b.failure != null && a.failure != b.failure;

// ─── 1. Activités, établissement, numéro ─────────────────────────────────────

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final t = Theme.of(context).textTheme;
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: _newFailure,
      listener: _showFailure,
      builder: (context, s) {
        return WamiScreen(
          showBack: false,
          glow: BizAccent.glow,
          actions: const [WamiTag('BUSINESS', tint: BizAccent.glow)],
          body: Gap(
            children: [
              const WamiLogo(height: 24),
              const SizedBox(height: 6),
              Text('Recevez des clients WAMI', style: t.headlineSmall?.copyWith(fontSize: 24, height: 1.25)),
              Text('Que proposez-vous ? Plusieurs choix possibles.', style: t.bodySmall),
              for (final a in BusinessActivity.values)
                WamiOptionTile(
                  title: a.label,
                  subtitle: a.hint,
                  selected: s.activities.contains(a),
                  showRadio: false,
                  onTap: () => cubit.toggleActivity(a),
                  leading: a.art != null ? ServiceIllustration(a.art!, size: 46) : IconBadge(a.icon, size: 46),
                  trailing: Icon(
                    s.activities.contains(a) ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: s.activities.contains(a) ? BizAccent.glow : context.wami.inkMuted,
                  ),
                ),
              const SectionLabel('Votre établissement'),
              WamiTextField(
                hint: 'Nom affiché aux clients',
                icon: Icons.storefront_rounded,
                initialValue: s.businessName,
                onChanged: cubit.setName,
              ),
              WamiTextField(
                hint: 'Quartier, ville (ex. Cadjèhoun, Cotonou)',
                icon: Icons.place_outlined,
                initialValue: s.district,
                onChanged: cubit.setDistrict,
              ),
              const SectionLabel('Numéro du gérant'),
              WamiTextField(
                hint: '01 97 00 00 00',
                prefixText: '+229 ',
                keyboardType: TextInputType.phone,
                initialValue: s.phone,
                onChanged: cubit.setPhone,
              ),
            ],
          ),
          bottom: WamiPrimaryButton(
            label: 'Recevoir le code',
            loading: s.busy,
            onPressed: () async {
              if (await cubit.sendCode() && context.mounted) context.push(BizRoutes.code);
            },
          ),
        );
      },
    );
  }
}

// ─── 2. Code SMS ─────────────────────────────────────────────────────────────

class OtpPage extends StatefulWidget {
  const OtpPage({super.key, required this.onRegistered});

  /// Fourni par le routeur : passe la session en « vérification ».
  final VoidCallback onRegistered;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  String _code = '';

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: _newFailure,
      listener: _showFailure,
      builder: (context, s) {
        return WamiScreen(
          title: 'Code de vérification',
          subtitle: 'Envoyé au +229 ${s.phone}',
          glow: BizAccent.glow,
          body: Gap(
            children: [
              const SizedBox(height: 12),
              CodeInput(onChanged: (v) => setState(() => _code = v), error: s.failure != null),
              Text('En démo, le code est 1234.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          bottom: WamiPrimaryButton(
            label: 'Créer mon espace',
            loading: s.busy,
            onPressed: _code.length == 4
                ? () async {
                    if (await cubit.verify(_code)) widget.onRegistered();
                  }
                : null,
          ),
        );
      },
    );
  }
}

// ─── 3. Pièces à fournir ─────────────────────────────────────────────────────

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key, required this.onActivated});

  /// Fourni par le routeur : ouvre l'application complète.
  final VoidCallback onActivated;

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  @override
  void initState() {
    super.initState();
    context.read<OnboardingCubit>().watchChecklist();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final t = Theme.of(context).textTheme;
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: _newFailure,
      listener: _showFailure,
      builder: (context, s) {
        final c = s.checklist;
        if (c == null) return const Scaffold(body: WamiLoading(label: 'Chargement de votre dossier…'));
        return WamiScreen(
          showBack: false,
          title: 'Vérification',
          subtitle: '${c.approvedCount} sur ${c.items.length} validées',
          glow: BizAccent.glow,
          body: Gap(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: c.progress,
                  minHeight: 6,
                  color: BizAccent.glow,
                  backgroundColor: context.wami.glass,
                ),
              ),
              Text(
                'Votre établissement devient visible dès que tout est validé. '
                'Délai habituel : à valider (24 à 48 h ?).',
                style: t.bodySmall,
              ),
              GlassGroup(children: [
                for (final i in c.items)
                  ListRow(
                    title: i.label,
                    subtitle: i.rejectReason ?? '${i.state.label} · ${i.hint}',
                    icon: switch (i.state) {
                      ChecklistState.approved => Icons.check_circle_rounded,
                      ChecklistState.sent => Icons.hourglass_top_rounded,
                      ChecklistState.rejected => Icons.error_outline_rounded,
                      ChecklistState.todo => Icons.upload_file_rounded,
                    },
                    iconColor: switch (i.state) {
                      ChecklistState.approved => WamiColors.success,
                      ChecklistState.rejected => WamiColors.danger,
                      _ => BizAccent.glow,
                    },
                    trailing: i.state.needsAction
                        ? (s.sendingId == i.id
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : TextButton(onPressed: () => cubit.send(i), child: const Text('Envoyer')))
                        : null,
                  ),
              ]),
            ],
          ),
          bottom: WamiPrimaryButton(
            label: c.isComplete ? 'Ouvrir mon espace' : 'En attente de validation',
            onPressed: c.isComplete ? widget.onActivated : null,
          ),
        );
      },
    );
  }
}
