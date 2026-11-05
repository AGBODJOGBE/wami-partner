import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/pro_accent.dart';
import '../../domain/entities/driver_profile.dart';
import '../cubit/profile_cubit.dart';

/// Mon profil : nom, adresse, e-mail, téléphone (avec codes de confirmation) et suppression du compte.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.onDeleted});

  /// Fourni par le routeur : ferme la session après la suppression du compte.
  final VoidCallback onDeleted;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _city = TextEditingController();
  final _quarter = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _emailCode = TextEditingController();
  final _phoneCode = TextEditingController();
  bool _filled = false;
  bool _emailSent = false;
  bool _phoneSent = false;

  @override
  void dispose() {
    for (final c in [_first, _last, _city, _quarter, _email, _phone, _emailCode, _phoneCode]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(DriverProfile p) {
    if (_filled) return;
    _filled = true;
    _first.text = p.firstName;
    _last.text = p.lastName;
    _city.text = p.city;
    _quarter.text = p.quarter;
    _email.text = p.email ?? '';
  }

  Widget _save(String label, VoidCallback onTap, bool busy) =>
      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: busy ? null : onTap, child: Text(label)));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (a, b) => (b.failure != null && a.failure != b.failure) || (b.notice != null && a.notice != b.notice),
      listener: (context, s) => showWamiMessage(context, s.failure?.message ?? s.notice!),
      builder: (context, s) {
        final p = s.profile;
        if (p != null) _fill(p);
        final cubit = context.read<ProfileCubit>();
        return WamiScreen(
          title: 'Mon profil',
          glow: ProAccent.glow,
          body: p == null
              ? const SizedBox(height: 300, child: WamiLoading())
              : Gap(
                  children: [
                    const SectionLabel('Nom'),
                    WamiTextField(hint: 'Prénom', controller: _first),
                    WamiTextField(hint: 'Nom', controller: _last),
                    _save('Enregistrer le nom', () => cubit.change(ChangeName(_first.text, _last.text)), s.busy),
                    const SectionLabel('Adresse'),
                    WamiTextField(hint: 'Ville', controller: _city),
                    WamiTextField(hint: 'Quartier', controller: _quarter),
                    _save('Enregistrer l’adresse', () => cubit.change(ChangeAddress(_city.text, _quarter.text)), s.busy),
                    const SectionLabel('E-mail'),
                    WamiTextField(hint: 'adresse@exemple.com', controller: _email, keyboardType: TextInputType.emailAddress),
                    Text(p.email == null ? 'Aucun e-mail' : (p.emailVerified ? 'E-mail confirmé' : 'E-mail à confirmer'), style: t.bodySmall),
                    _save(p.email == null ? 'Ajouter l’e-mail' : 'Changer l’e-mail', () async {
                      if (await cubit.change(ChangeEmail(_email.text, hadEmail: p.email != null))) setState(() => _emailSent = true);
                    }, s.busy),
                    if (_emailSent || (p.email != null && !p.emailVerified)) ...[
                      WamiTextField(hint: 'Code reçu par e-mail', controller: _emailCode),
                      _save('Confirmer l’e-mail', () async {
                        if (await cubit.change(VerifyEmail(_emailCode.text))) setState(() => _emailSent = false);
                      }, s.busy),
                    ],
                    const SectionLabel('Téléphone'),
                    Text('${p.phone} · ${p.phoneVerified ? 'confirmé' : 'à confirmer'}', style: t.bodySmall),
                    WamiTextField(hint: 'Nouveau numéro', prefixText: '+229 ', controller: _phone, keyboardType: TextInputType.phone),
                    _save('Changer le numéro', () async {
                      if (await cubit.change(ChangePhone(_phone.text))) setState(() => _phoneSent = true);
                    }, s.busy),
                    if (_phoneSent || !p.phoneVerified) ...[
                      WamiTextField(hint: 'Code reçu par SMS', controller: _phoneCode, keyboardType: TextInputType.number),
                      _save('Confirmer le numéro', () async {
                        if (await cubit.change(VerifyPhone(_phoneCode.text))) setState(() => _phoneSent = false);
                      }, s.busy),
                    ],
                    const SizedBox(height: 12),
                    GlassGroup(children: [
                      ListRow(
                        title: 'Supprimer mon compte',
                        subtitle: 'Définitif. Mot de passe demandé.',
                        icon: Icons.delete_forever_rounded,
                        iconColor: context.wami.danger,
                        onTap: s.busy ? null : () => _confirmDelete(context),
                      ),
                    ]),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final password = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer mon compte ?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Vous perdrez l’accès à vos missions. Assurez-vous d’avoir retiré votre solde.'),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(hintText: 'Mot de passe')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Retour')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    final pwd = password.text;
    password.dispose();
    if (ok == true && await cubit.deleteAccount(pwd)) widget.onDeleted();
  }
}
