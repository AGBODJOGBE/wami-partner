import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/photo_picker.dart';
import '../../../../shared/pro_accent.dart';
import '../../../../shared/routes.dart';
import '../../domain/entities/partner.dart';
import '../cubit/onboarding_cubit.dart';

void _showFailure(BuildContext context, OnboardingState s) {
  if (s.failure != null) showWamiMessage(context, s.failure!.message);
}

bool _newFailure(OnboardingState a, OnboardingState b) => b.failure != null && a.failure != b.failure;

// ─── 1. Métier, véhicule, numéro ─────────────────────────────────────────────

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
          glow: ProAccent.glow,
          actions: const [WamiTag('PRO', tint: ProAccent.glow)],
          title: null,
          body: Gap(
            children: [
              const WamiLogo(height: 24),
              const SizedBox(height: 6),
              Text('Gagnez de l’argent à votre rythme', style: t.headlineSmall?.copyWith(fontSize: 24, height: 1.25)),
              Text('Choisissez votre activité. Vous pourrez en ajouter une autre plus tard.', style: t.bodySmall),
              for (final a in PartnerActivity.values)
                WamiOptionTile(
                  title: a.label,
                  subtitle: a.hint,
                  selected: s.activities.contains(a),
                  showRadio: false,
                  onTap: () => cubit.toggleActivity(a),
                  leading: IconBadge(a == PartnerActivity.driver ? Icons.local_taxi_rounded : Icons.inventory_2_outlined, size: 46),
                  trailing: Icon(
                    s.activities.contains(a) ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: s.activities.contains(a) ? WamiColors.orangeLight : context.wami.inkMuted,
                  ),
                ),
              const SectionLabel('Votre véhicule'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final v in VehicleType.values)
                  WamiChip(label: v.label, selected: s.vehicle == v, onTap: () => cubit.setVehicle(v)),
              ]),
              const SectionLabel('Votre numéro'),
              WamiTextField(
                hint: '01 97 00 00 00',
                prefixText: '+229 ',
                keyboardType: TextInputType.phone,
                initialValue: s.phone,
                onChanged: cubit.setPhone,
              ),
              Text('Un code vous est envoyé par SMS.', style: t.bodySmall?.copyWith(fontSize: 11.5)),
            ],
          ),
          bottom: Column(mainAxisSize: MainAxisSize.min, children: [
            WamiPrimaryButton(
              label: 'Recevoir le code',
              loading: s.busy,
              onPressed: () async {
                if (await cubit.sendCode() && context.mounted) context.push(ProRoutes.code);
              },
            ),
            TextButton(onPressed: () => context.push(ProRoutes.login), child: const Text('J’ai déjà un compte')),
          ]),
        );
      },
    );
  }
}

// ─── 2. Code SMS ─────────────────────────────────────────────────────────────

class OtpPage extends StatelessWidget {
  const OtpPage({super.key, required this.onRegistered});

  /// Conservé pour compatibilité du routeur : la session s'ouvre à la fin du formulaire de profil.
  final VoidCallback onRegistered;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: _newFailure,
      listener: _showFailure,
      builder: (context, s) {
        return WamiScreen(
          title: 'Code de vérification',
          glow: ProAccent.glow,
          body: Gap(
            children: [
              Text('Saisissez le code à 6 chiffres reçu au +229 ${s.phone}.', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              CodeInput(
                length: 6,
                onChanged: (code) async {
                  if (code.length < 6) return;
                  if (await cubit.verify(code) && context.mounted) context.push(ProRoutes.register);
                },
              ),
              if (s.busy) const SizedBox(height: 60, child: WamiLoading()),
              Center(
                child: TextButton(onPressed: s.busy ? null : cubit.sendCode, child: const Text('Renvoyer le code')),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── 3. Documents ────────────────────────────────────────────────────────────

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  @override
  void initState() {
    super.initState();
    context.read<OnboardingCubit>().loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: _newFailure,
      listener: _showFailure,
      builder: (context, s) {
        final next = s.documents.where((d) => !d.status.isSent).firstOrNull;
        return WamiScreen(
          title: 'Vos documents',
          showBack: false,
          glow: ProAccent.glow,
          body: s.documents.isEmpty
              ? const SizedBox(height: 300, child: WamiLoading())
              : Gap(
                  children: [
                    Row(children: [
                      Expanded(child: Text('${s.sentCount} sur ${s.documents.length} envoyés', style: Theme.of(context).textTheme.bodySmall)),
                      Text('Brouillon enregistré', style: TextStyle(fontSize: 12, color: context.wami.orangeStrong)),
                    ]),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: s.sentCount / s.documents.length,
                        minHeight: 6,
                        color: WamiColors.orangeLight,
                        backgroundColor: context.wami.ink.withValues(alpha: 0.1),
                      ),
                    ),
                    GlassGroup(children: [
                      for (final d in s.documents)
                        ListRow(
                          title: d.type.label,
                          subtitle: d.rejectionReason ?? d.type.hint,
                          icon: _icon(d.type),
                          iconColor: d.status.isSent ? ProAccent.glow : WamiColors.orangeLight,
                          trailing: s.uploading == d.type
                              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : WamiTag(d.status.label, tint: _tint(d.status)),
                          onTap: d.status.isSent ? null : () => context.push(ProRoutes.capture, extra: d.type),
                        ),
                    ]),
                    Text('Liste exacte des pièces exigées : à valider.', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.5)),
                  ],
                ),
          bottom: s.allSent
              ? WamiPrimaryButton(
                  label: 'Envoyer mon dossier',
                  loading: s.busy,
                  onPressed: () async {
                    if (await cubit.submit() && context.mounted) context.go(ProRoutes.status);
                  },
                )
              : WamiPrimaryButton(
                  label: next == null ? 'Chargement…' : 'Envoyer : ${next.type.label}',
                  icon: Icons.photo_camera_outlined,
                  onPressed: next == null ? null : () => context.push(ProRoutes.capture, extra: next.type),
                ),
        );
      },
    );
  }

  IconData _icon(DocumentType t) => switch (t) {
        DocumentType.identity => Icons.badge_outlined,
        DocumentType.photo => Icons.face_retouching_natural_outlined,
        DocumentType.license => Icons.credit_card_outlined,
        DocumentType.registration => Icons.description_outlined,
        DocumentType.insurance => Icons.verified_user_outlined,
      };

  Color _tint(DocumentStatus s) => switch (s) {
        DocumentStatus.approved => WamiColors.success,
        DocumentStatus.pending => WamiColors.glowHebergement,
        DocumentStatus.rejected => WamiColors.danger,
        DocumentStatus.missing => WamiColors.white,
      };
}

// ─── 4. Prise de photo guidée ────────────────────────────────────────────────

/// Écran de capture : le déclencheur ouvre l'appareil photo (image_picker), la photo
/// part aussitôt au serveur.
class CapturePage extends StatelessWidget {
  const CapturePage({super.key, required this.type});
  final DocumentType type;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return Scaffold(
      backgroundColor: const Color(0xFF0B111E),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(colors: [Color(0xFF2A3550), Color(0xFF0B111E)]),
                ),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: WamiColors.orangeLight, width: 3),
                      boxShadow: [BoxShadow(color: WamiColors.orange.withValues(alpha: 0.5), blurRadius: 22)],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                WamiIconButton(icon: Icons.arrow_back_ios_new_rounded, tooltip: 'Retour', onPressed: () => context.pop()),
                const SizedBox(width: 12),
                Text(type.label, style: Theme.of(context).textTheme.titleMedium),
              ]),
            ),
            const Align(
              alignment: Alignment(0, -0.55),
              child: Text('Placez le document dans le cadre', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const Align(
              alignment: Alignment(0, 0.42),
              child: Text(
                'Pas de reflet, les quatre coins visibles.\nLa photo est vérifiée avant l’envoi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Color(0xFFA9B2C6)),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: BlocBuilder<OnboardingCubit, OnboardingState>(
                  builder: (context, s) {
                    if (s.uploading == type) return const WamiLoading(label: 'Envoi…');
                    return Semantics(
                      button: true,
                      label: 'Prendre la photo',
                      child: GestureDetector(
                        onTap: () async {
                          final path = await PhotoPicker.camera();
                          if (path == null) return;
                          await cubit.upload(type, path);
                          if (context.mounted) context.pop();
                        },
                        child: Container(
                          width: 76,
                          height: 76,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(shape: BoxShape.circle, gradient: WamiEffects.ctaGradient),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 5. Suivi de la validation ───────────────────────────────────────────────

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key, required this.onActivated});
  final VoidCallback onActivated;

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  @override
  void initState() {
    super.initState();
    context.read<OnboardingCubit>().watchVerification();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, s) {
        final v = s.verification;
        final steps = <(String, String, bool)>[
          ('Dossier envoyé', 'Documents reçus', v?.documentsSent ?? false),
          ('Vérification par WAMI', 'Sous ${v?.reviewDelay ?? '[48 h]'} · à valider', v?.reviewDone ?? false),
          ('Formation en ligne', 'Règles, sécurité, attente et pause · 15 min', v?.trainingDone ?? false),
          ('Contrôle du véhicule', 'Au point WAMI · à valider', v?.vehicleChecked ?? false),
        ];
        final current = steps.indexWhere((st) => !st.$3);
        final active = v?.isActive ?? false;
        return WamiScreen(
          title: 'Votre dossier avance',
          showBack: false,
          glow: ProAccent.glow,
          body: Gap(
            children: [
              Text('Nous vous prévenons à chaque étape.', style: Theme.of(context).textTheme.bodySmall),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (var i = 0; i < steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StepDot(done: steps[i].$3, current: i == current, index: i + 1),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(steps[i].$1, style: Theme.of(context).textTheme.titleSmall),
                                  Text(steps[i].$2, style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (!(v?.trainingDone ?? true))
                GlassCard(
                  onTap: s.busy ? null : cubit.doTraining,
                  borderColor: ProAccent.glow.withValues(alpha: 0.5),
                  child: const ListRow(
                    title: 'Commencez la formation',
                    subtitle: 'Disponible sans attendre la vérification',
                    icon: Icons.play_arrow_rounded,
                    iconColor: ProAccent.glow,
                  ),
                ),
            ],
          ),
          bottom: WamiPrimaryButton(
            label: active ? 'Commencer à travailler' : 'Vérification en cours…',
            onPressed: active
                ? () {
                    widget.onActivated();
                    context.go(ProRoutes.missions);
                  }
                : null,
          ),
        );
      },
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.done, required this.current, required this.index});
  final bool done;
  final bool current;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? WamiColors.success : (current ? null : context.wami.ink.withValues(alpha: 0.12)),
        gradient: current && !done ? WamiEffects.ctaGradient : null,
        boxShadow: current && !done ? WamiEffects.halo() : null,
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 14, color: Color(0xFF0A1A12))
          : Text('$index', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: current ? Colors.white : context.wami.inkMuted)),
    );
  }
}
