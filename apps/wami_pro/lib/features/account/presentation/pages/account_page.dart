import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/pro_accent.dart';
import '../../../../shared/routes.dart';
import '../../domain/entities/partner_account.dart';
import '../cubit/account_cubit.dart';

/// Onglet Compte : véhicule, documents à jour, préférences de missions.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.onLogout});

  /// Fourni par le routeur (la session vit dans la couche app).
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocConsumer<AccountCubit, AccountState>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      builder: (context, s) {
        final a = s.account;
        final cubit = context.read<AccountCubit>();
        return WamiBackground(
          glow: ProAccent.glow,
          child: SafeArea(
            bottom: false,
            child: a == null
                ? const WamiLoading()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(WamiSpace.screen, 12, WamiSpace.screen, 110),
                    children: [
                      Row(children: [
                        WamiAvatar(initials: Fmt.initials(a.name.replaceAll(RegExp(r'[\[\]]'), '')), size: 56),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a.name, style: t.titleMedium),
                            Text('${a.role} · depuis ${a.memberSince}', style: t.bodySmall),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      GlassCard(
                        child: ListRow(
                          title: a.vehicle,
                          subtitle: a.plate,
                          icon: Icons.two_wheeler_rounded,
                          iconColor: ProAccent.glow,
                          trailing: TextButton(onPressed: () {}, child: const Text('Changer')),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const SectionLabel('Documents'),
                      const SizedBox(height: 6),
                      GlassGroup(children: [
                        for (final c in a.compliance)
                          ListRow(
                            title: c.label,
                            subtitle: c.daysLeft == null ? null : 'Expire dans ${c.daysLeft} jours',
                            icon: Icons.description_outlined,
                            iconColor: _color(c.state),
                            trailing: WamiTag(_label(c.state), tint: _color(c.state)),
                          ),
                      ]),
                      const SizedBox(height: 14),
                      const SectionLabel('Préférences'),
                      const SizedBox(height: 6),
                      GlassGroup(children: [
                        ToggleRow(
                          title: 'Recevoir aussi des livraisons',
                          value: a.preferences.acceptDeliveries,
                          onChanged: (v) => cubit.updatePreferences((p) => p.copyWith(acceptDeliveries: v)),
                        ),
                        ToggleRow(
                          title: 'Accepter les paiements en espèces',
                          value: a.preferences.acceptCash,
                          onChanged: (v) => cubit.updatePreferences((p) => p.copyWith(acceptCash: v)),
                        ),
                        ToggleRow(
                          title: 'Courses longues (hors ville)',
                          value: a.preferences.longTrips,
                          onChanged: (v) => cubit.updatePreferences((p) => p.copyWith(longTrips: v)),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      GlassGroup(children: [
                        ListRow(title: 'Mon profil', icon: Icons.person_outline_rounded, onTap: () => context.push(ProRoutes.profile)),
                        ListRow(title: 'Mes véhicules', icon: Icons.directions_car_outlined, onTap: () => context.push(ProRoutes.vehicles)),
                        ListRow(title: 'Historique', icon: Icons.history_rounded, onTap: () => context.push(ProRoutes.history)),
                        ListRow(title: 'Trajets programmés', icon: Icons.alt_route_rounded, onTap: () => context.push(ProRoutes.intercity)),
                        ListRow(title: 'Parrainage', icon: Icons.group_add_outlined, onTap: () => context.push(ProRoutes.referrals)),
                        ListRow(title: 'Notifications', icon: Icons.notifications_none_rounded, onTap: () => context.push(ProRoutes.notifications)),
                        ListRow(title: 'Bonus', icon: Icons.card_giftcard_rounded, onTap: () => context.push(ProRoutes.bonus)),
                        ListRow(title: 'Mon contrat de véhicule', icon: Icons.assignment_outlined, onTap: () => context.push(ProRoutes.contract)),
                        ListRow(title: 'Changer mon mot de passe', icon: Icons.lock_outline_rounded, onTap: () => context.push(ProRoutes.password)),
                      ]),
                      const SizedBox(height: 14),
                      GlassGroup(children: [
                        ListRow(title: 'Assistance partenaires', icon: Icons.support_agent_rounded, onTap: () {}),
                        ListRow(title: 'Se déconnecter', icon: Icons.logout_rounded, iconColor: context.wami.danger, onTap: onLogout),
                      ]),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Color _color(ComplianceState s) => switch (s) {
        ComplianceState.ok => WamiColors.success,
        ComplianceState.expiringSoon => WamiColors.glowHebergement,
        ComplianceState.expired => WamiColors.danger,
      };

  String _label(ComplianceState s) => switch (s) {
        ComplianceState.ok => 'À jour',
        ComplianceState.expiringSoon => 'Renouveler',
        ComplianceState.expired => 'Expiré',
      };
}

/// Changement de mot de passe, ouvert depuis l'onglet Compte.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PasswordCubit, AccountState>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      builder: (context, s) {
        return WamiScreen(
          title: 'Mot de passe',
          glow: ProAccent.glow,
          body: Gap(
            children: [
              WamiTextField(hint: 'Mot de passe actuel', controller: _current, obscureText: true, icon: Icons.lock_outline_rounded),
              WamiTextField(hint: 'Nouveau mot de passe', controller: _next, obscureText: true, icon: Icons.lock_reset_rounded),
              WamiTextField(hint: 'Confirmer le nouveau mot de passe', controller: _confirm, obscureText: true, icon: Icons.lock_reset_rounded),
              Text('8 caractères minimum, avec une majuscule, une minuscule et un chiffre.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.5)),
            ],
          ),
          bottom: WamiPrimaryButton(
            label: 'Changer le mot de passe',
            loading: s.status.isLoading,
            onPressed: () async {
              final ok = await context.read<PasswordCubit>().submit(current: _current.text, next: _next.text, confirm: _confirm.text);
              if (ok && context.mounted) {
                showWamiMessage(context, 'Mot de passe modifié.');
                context.pop();
              }
            },
          ),
        );
      },
    );
  }
}
