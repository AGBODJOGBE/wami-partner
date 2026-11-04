import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/pro_accent.dart';
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
