import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/biz_accent.dart';
import '../../../../shared/data_state.dart';
import '../../domain/entities/lodging.dart';
import '../cubit/lodging_cubits.dart';

/// Réservation prise au comptoir ou par téléphone. Renvoie `true` si créée.
class DeskBookingPage extends StatelessWidget {
  const DeskBookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DeskBookingCubit>();
    final t = Theme.of(context).textTheme;
    return BlocConsumer<DeskBookingCubit, DeskBookingState>(
      listenWhen: (a, b) => (b.failure != null && a.failure != b.failure) || (a.created == null && b.created != null),
      listener: (context, s) {
        if (s.failure != null) showWamiMessage(context, s.failure!.message);
      },
      builder: (context, s) {
        final created = s.created;
        if (created != null) {
          return Scaffold(
            body: WamiSuccessView(
              icon: Icons.event_available_rounded,
              positive: true,
              title: 'Réservation enregistrée',
              message: '${created.guestName} · code d’arrivée ${created.code}',
              children: [WamiPrimaryButton(label: 'Retour au planning', onPressed: () => Navigator.pop(context, true))],
            ),
          );
        }
        final today = dateOnly(DateTime.now());
        final tomorrow = DateTime(today.year, today.month, today.day + 1);
        return WamiScreen(
          title: 'Réservation au comptoir',
          glow: BizAccent.glow,
          body: Gap(children: [
            const SectionLabel('Chambre'),
            if (s.types.isEmpty) const SizedBox(height: 80, child: WamiLoading()),
            for (final rt in s.types)
              WamiOptionTile(
                title: rt.name,
                subtitle: '${Fmt.fcfa(rt.nightlyPrice)} la nuit',
                selected: rt.id == s.typeId,
                onTap: () => cubit.selectType(rt.id),
              ),
            const SectionLabel('Client'),
            WamiTextField(hint: 'Nom du client', icon: Icons.person_outline_rounded, onChanged: cubit.setGuest),
            const SectionLabel('Arrivée'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              WamiChip(label: 'Aujourd’hui', selected: s.checkIn == today, onTap: () => cubit.setCheckIn(today)),
              WamiChip(label: 'Demain', selected: s.checkIn == tomorrow, onTap: () => cubit.setCheckIn(tomorrow)),
              WamiChip(
                label: s.checkIn.isAfter(tomorrow) ? Fmt.dayMonth(s.checkIn) : 'Autre date',
                icon: Icons.calendar_month_rounded,
                selected: s.checkIn.isAfter(tomorrow),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    firstDate: today,
                    lastDate: DateTime(today.year + 1, today.month, today.day),
                    initialDate: s.checkIn,
                  );
                  if (d != null) cubit.setCheckIn(d);
                },
              ),
            ]),
            CounterStepper(label: 'Nuits', value: s.nights, min: 1, max: 30, onChanged: cubit.setNights),
            GlassCard(
              child: Column(children: [
                InfoRow('Départ', Fmt.dayMonth(s.checkOut)),
                InfoRow('Total à encaisser', Fmt.fcfa(s.total), strong: true),
              ]),
            ),
            Text('Paiement au comptoir : hors commission WAMI ? À valider.', style: t.bodySmall),
          ]),
          bottom: WamiPrimaryButton(
            label: 'Enregistrer',
            loading: s.busy,
            onPressed: s.typeId == null ? null : cubit.submit,
          ),
        );
      },
    );
  }
}

/// Arrivée du client : il présente le code à 6 chiffres reçu dans l'app.
class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key, required this.establishmentId});
  final String establishmentId;

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  String _code = '';

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CheckInCubit>();
    return BlocBuilder<CheckInCubit, DataState<Booking>>(
      builder: (context, s) {
        final b = s.data;
        if (b != null) {
          return Scaffold(
            body: WamiSuccessView(
              icon: Icons.key_rounded,
              positive: true,
              title: 'Bienvenue, ${b.guestName}',
              message: '${b.nights} nuit${b.nights > 1 ? 's' : ''} · départ le ${Fmt.dayMonth(b.checkOut)}',
              children: [WamiPrimaryButton(label: 'Terminer', onPressed: () => Navigator.pop(context, true))],
            ),
          );
        }
        return WamiScreen(
          title: 'Check-in',
          subtitle: 'Code présenté par le client',
          glow: BizAccent.glow,
          body: Gap(children: [
            const SizedBox(height: 12),
            CodeInput(length: 6, error: s.failure != null, onChanged: (v) => setState(() => _code = v)),
            if (s.failure != null)
              Text(s.failure!.message, textAlign: TextAlign.center, style: TextStyle(color: context.wami.danger))
            else
              Text('En démo : 482193.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            Text('Scanner le QR code du client : à valider (paquet de scan à ajouter).',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ]),
          bottom: WamiPrimaryButton(
            label: 'Valider l’arrivée',
            loading: s.busy,
            onPressed: _code.length == 6 ? () => cubit.submit(widget.establishmentId, _code) : null,
          ),
        );
      },
    );
  }
}
