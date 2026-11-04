import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/biz_accent.dart';
import '../../../../shared/data_state.dart';
import '../../../../shared/routes.dart';
import '../../domain/entities/business_account.dart';
import '../cubit/account_cubit.dart';

/// Onglet « Compte » : entreprise, équipe, avis, déconnexion.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.onLogout});

  /// Fourni par le routeur : la session repasse à « déconnecté ».
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocBuilder<AccountCubit, DataState<BusinessAccount>>(
      builder: (context, s) {
        final a = s.data;
        return WamiScreen(
          showBack: false,
          title: 'Compte',
          glow: BizAccent.glow,
          body: a == null
              ? (s.status == LoadStatus.failure
                  ? WamiErrorView(failure: s.failure!, onRetry: context.read<AccountCubit>().load)
                  : const SizedBox(height: 300, child: WamiLoading()))
              : Gap(children: [
                  GlassCard(
                    child: Row(children: [
                      WamiAvatar(initials: Fmt.initials(a.ownerName), size: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a.businessName, style: t.titleMedium),
                          Text('${a.ownerName} · ${a.phone}', style: t.bodySmall),
                          Text('Partenaire depuis ${a.memberSince}', style: t.bodySmall),
                        ]),
                      ),
                    ]),
                  ),
                  GlassGroup(children: [
                    ListRow(
                      title: 'Équipe',
                      subtitle: '${a.team.length} membre${a.team.length > 1 ? 's' : ''}',
                      icon: Icons.group_rounded,
                      trailing: Icon(Icons.chevron_right_rounded, color: context.wami.inkMuted),
                      onTap: () async {
                        await context.push(BizRoutes.team);
                        if (context.mounted) context.read<AccountCubit>().load();
                      },
                    ),
                    ListRow(
                      title: 'Avis clients',
                      subtitle: 'Lire et répondre',
                      icon: Icons.star_rounded,
                      iconColor: WamiColors.star,
                      trailing: Icon(Icons.chevron_right_rounded, color: context.wami.inkMuted),
                      onTap: () => context.push(BizRoutes.reviews),
                    ),
                    const ListRow(title: 'Documents et contrat', subtitle: 'À valider', icon: Icons.description_outlined),
                    const ListRow(title: 'Aide et support', subtitle: 'À valider : WhatsApp, appel ?', icon: Icons.support_agent_rounded),
                  ]),
                  WamiGhostButton(label: 'Se déconnecter', icon: Icons.logout_rounded, onPressed: onLogout),
                ]),
        );
      },
    );
  }
}

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AccountCubit>();
    final t = Theme.of(context).textTheme;
    return BlocConsumer<AccountCubit, DataState<BusinessAccount>>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, s) => showWamiMessage(context, s.failure!.message),
      builder: (context, s) {
        final a = s.data;
        return WamiScreen(
          title: 'Équipe',
          subtitle: 'Chacun se connecte avec son numéro',
          glow: BizAccent.glow,
          body: a == null
              ? (s.status == LoadStatus.failure
                  ? WamiErrorView(failure: s.failure!, onRetry: cubit.load)
                  : const SizedBox(height: 300, child: WamiLoading()))
              : Gap(children: [
                  GlassGroup(children: [
                    for (final m in a.team)
                      ListRow(
                        leading: WamiAvatar(initials: Fmt.initials(m.name), size: 38),
                        title: m.name,
                        subtitle: '${m.role.label}${m.pending ? ' · invitation envoyée' : ''}',
                        trailing: m.role == TeamRole.owner
                            ? null
                            : WamiIconButton(
                                icon: Icons.person_remove_outlined,
                                tooltip: 'Retirer',
                                size: 36,
                                onPressed: s.busy ? null : () => cubit.remove(m),
                              ),
                      ),
                  ]),
                  const SectionLabel('Rôles'),
                  for (final r in TeamRole.values) Text('${r.label} : ${r.rights}.', style: t.bodySmall),
                ]),
          bottom: WamiPrimaryButton(
            label: 'Inviter un membre',
            icon: Icons.person_add_alt_1_rounded,
            loading: s.busy,
            onPressed: a == null ? null : () => _invite(context, cubit),
          ),
        );
      },
    );
  }

  Future<void> _invite(BuildContext context, AccountCubit cubit) async {
    final invite = await showBizSheet<(String, String, TeamRole)>(context, children: (_) => const [_InviteForm()]);
    if (invite == null) return;
    final ok = await cubit.invite(name: invite.$1, phone: invite.$2, role: invite.$3);
    if (ok && context.mounted) showWamiMessage(context, 'Invitation envoyée par SMS.');
  }
}

class _InviteForm extends StatefulWidget {
  const _InviteForm();

  @override
  State<_InviteForm> createState() => _InviteFormState();
}

class _InviteFormState extends State<_InviteForm> {
  String _name = '';
  String _phone = '';
  TeamRole _role = TeamRole.staff;

  @override
  Widget build(BuildContext context) {
    return Gap(children: [
      Text('Inviter un membre', style: Theme.of(context).textTheme.titleMedium),
      WamiTextField(hint: 'Nom', icon: Icons.person_outline_rounded, onChanged: (v) => _name = v),
      WamiTextField(hint: '01 97 00 00 00', prefixText: '+229 ', keyboardType: TextInputType.phone, onChanged: (v) => _phone = v),
      WamiSegmented<TeamRole>(
        options: const [(TeamRole.manager, 'Gérant'), (TeamRole.staff, 'Employé')],
        value: _role,
        onChanged: (r) => setState(() => _role = r),
      ),
      Text(_role.rights, style: Theme.of(context).textTheme.bodySmall),
      WamiPrimaryButton(label: 'Envoyer l’invitation', onPressed: () => Navigator.pop(context, (_name, _phone, _role))),
    ]);
  }
}
