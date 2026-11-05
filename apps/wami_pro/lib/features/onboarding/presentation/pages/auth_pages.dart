import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/pro_accent.dart';
import '../../../../shared/routes.dart';
import '../../domain/entities/partner.dart';
import '../cubit/onboarding_cubit.dart';

void _showFailure(BuildContext context, OnboardingState s) {
  if (s.failure != null) showWamiMessage(context, s.failure!.message);
}

bool _newFailure(OnboardingState a, OnboardingState b) => b.failure != null && a.failure != b.failure;

// ─── Création du compte : profil et véhicule ─────────────────────────────────

/// Dernière étape avant l'envoi des pièces : identité, mot de passe et véhicule.
/// Le serveur exige le véhicule dès la création (marque, modèle, année, couleur, plaque, places).
class RegisterProfilePage extends StatefulWidget {
  const RegisterProfilePage({super.key, required this.onRegistered});

  /// Appelé une fois le compte créé et la session ouverte.
  final VoidCallback onRegistered;

  @override
  State<RegisterProfilePage> createState() => _RegisterProfilePageState();
}

class _RegisterProfilePageState extends State<RegisterProfilePage> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _password = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _color = TextEditingController();
  final _plate = TextEditingController();
  final _referral = TextEditingController();
  Gender _gender = Gender.male;

  @override
  void dispose() {
    for (final c in [_first, _last, _password, _make, _model, _year, _color, _plate, _referral]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(OnboardingCubit cubit, OnboardingState s) async {
    final ok = await cubit.register(RegistrationForm(
      phone: s.phone,
      password: _password.text,
      firstName: _first.text,
      lastName: _last.text,
      gender: _gender,
      activities: s.activities,
      vehicle: s.vehicle,
      make: _make.text,
      model: _model.text,
      year: int.tryParse(_year.text.trim()) ?? 0,
      color: _color.text,
      plate: _plate.text,
      seats: s.vehicle.defaultSeats,
      referralCode: _referral.text,
    ));
    if (ok && mounted) {
      widget.onRegistered();
      context.go(ProRoutes.documents);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: _newFailure,
      listener: _showFailure,
      builder: (context, s) {
        return WamiScreen(
          title: 'Votre profil',
          glow: ProAccent.glow,
          body: Gap(
            children: [
              const SectionLabel('Vous'),
              WamiTextField(hint: 'Prénom', controller: _first),
              WamiTextField(hint: 'Nom', controller: _last),
              WamiSegmented<Gender>(
                options: [for (final g in Gender.values) (g, g.label)],
                value: _gender,
                onChanged: (g) => setState(() => _gender = g),
              ),
              WamiTextField(hint: 'Mot de passe', controller: _password, obscureText: true, icon: Icons.lock_outline_rounded),
              Text('8 caractères minimum, avec une majuscule, une minuscule et un chiffre.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.5)),
              SectionLabel('Votre ${s.vehicle.label.toLowerCase()}'),
              WamiTextField(hint: 'Marque (ex. Bajaj)', controller: _make),
              WamiTextField(hint: 'Modèle (ex. Boxer)', controller: _model),
              WamiTextField(hint: 'Année', controller: _year, keyboardType: TextInputType.number),
              WamiTextField(hint: 'Couleur', controller: _color),
              WamiTextField(hint: 'Plaque d’immatriculation', controller: _plate),
              const SectionLabel('Parrainage'),
              WamiTextField(hint: 'Code de parrainage (facultatif)', controller: _referral),
            ],
          ),
          bottom: WamiPrimaryButton(
            label: 'Créer mon compte',
            loading: s.busy,
            onPressed: () => _submit(cubit, s),
          ),
        );
      },
    );
  }
}

// ─── Connexion ───────────────────────────────────────────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLoggedIn});

  /// Appelé une fois connecté : le routeur lit alors l'avancement du dossier.
  final VoidCallback onLoggedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: _newFailure,
      listener: _showFailure,
      builder: (context, s) {
        return WamiScreen(
          title: 'Connexion',
          glow: ProAccent.glow,
          body: Gap(
            children: [
              WamiTextField(
                hint: '01 97 00 00 00',
                prefixText: '+229 ',
                keyboardType: TextInputType.phone,
                controller: _phone,
              ),
              WamiTextField(hint: 'Mot de passe', controller: _password, obscureText: true, icon: Icons.lock_outline_rounded),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => context.push(ProRoutes.forgot), child: const Text('Mot de passe oublié ?')),
              ),
            ],
          ),
          bottom: WamiPrimaryButton(
            label: 'Me connecter',
            loading: s.busy,
            onPressed: () async {
              if (await cubit.login(_phone.text, _password.text) && context.mounted) widget.onLoggedIn();
            },
          ),
        );
      },
    );
  }
}

// ─── Mot de passe oublié ─────────────────────────────────────────────────────

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: _newFailure,
      listener: _showFailure,
      builder: (context, s) {
        return WamiScreen(
          title: 'Nouveau mot de passe',
          glow: ProAccent.glow,
          body: Gap(
            children: [
              WamiTextField(
                hint: '01 97 00 00 00',
                prefixText: '+229 ',
                keyboardType: TextInputType.phone,
                controller: _phone,
              ),
              if (_sent) ...[
                Text('Saisissez le code reçu par SMS et votre nouveau mot de passe.', style: Theme.of(context).textTheme.bodySmall),
                WamiTextField(hint: 'Code reçu par SMS', controller: _code, keyboardType: TextInputType.number),
                WamiTextField(hint: 'Nouveau mot de passe', controller: _password, obscureText: true, icon: Icons.lock_outline_rounded),
              ] else
                Text('Un code vous est envoyé par SMS.', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          bottom: WamiPrimaryButton(
            label: _sent ? 'Changer le mot de passe' : 'Recevoir le code',
            loading: s.busy,
            onPressed: () async {
              if (!_sent) {
                if (await cubit.requestPasswordReset(_phone.text)) setState(() => _sent = true);
                return;
              }
              if (await cubit.resetPassword(_phone.text, _code.text, _password.text) && context.mounted) {
                showWamiMessage(context, 'Mot de passe modifié. Connectez-vous.');
                context.pop();
              }
            },
          ),
        );
      },
    );
  }
}
