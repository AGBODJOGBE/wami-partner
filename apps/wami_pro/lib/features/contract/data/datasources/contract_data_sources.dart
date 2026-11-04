import 'package:wami_core/wami_core.dart';

import '../../domain/entities/contract.dart';

abstract interface class ContractRemoteDataSource {
  Future<VehicleContract?> contract();
}

int _int(Object? v) => v is num ? v.round() : 0;

InstallmentState _state(Object? s) => switch (s) {
      'PAYEE' => InstallmentState.paid,
      'IMPAYEE' => InstallmentState.late,
      'EN_RECOUVREMENT' || 'PARTIELLEMENT_RECOUVREE' => InstallmentState.collecting,
      'ANNULEE' => InstallmentState.cancelled,
      _ => InstallmentState.pending,
    };

/// Routes `/api/driver/contract` (contrat), `/installments` (échéances) et `/status` (blocage).
/// Un partenaire sans contrat reçoit une erreur 4xx : la page affiche alors un état vide.
class ContractApiDataSource implements ContractRemoteDataSource {
  const ContractApiDataSource(this._api);
  final ApiClient _api;

  @override
  Future<VehicleContract?> contract() async {
    final Map<String, dynamic> c;
    try {
      c = await _api.get('/api/driver/contract');
    } on BusinessRuleException {
      return null;
    }
    final inst = await _api.get('/api/driver/contract/installments');
    final st = await _api.get('/api/driver/contract/status');
    final next = st['nextEcheance'] is Map ? st['nextEcheance'] as Map : null;
    return VehicleContract(
      status: (c['statut'] as String?) ?? '',
      total: _int(c['montantTotal']),
      paid: _int(c['montantPaye']),
      remaining: _int(c['montantRestant']),
      unpaidCount: _int(st['nbImpayes'] ?? c['nbImpayes']),
      blocked: st['isBlocked'] == true,
      byRevenue: st['modeRemboursement'] == 'PAR_REVENU',
      nextDueDate: next == null ? null : DateTime.tryParse('${next['dateEcheance']}')?.toLocal(),
      nextAmount: next == null ? null : _int(next['montant']),
      installments: ((inst['items'] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>().map((i) {
        return Installment(
          number: _int(i['numero']),
          dueDate: DateTime.tryParse('${i['dateEcheance']}')?.toLocal() ?? DateTime.now(),
          amount: _int(i['montant']),
          paid: _int(i['montantPaye']),
          state: _state(i['statut']),
        );
      }).toList(),
    );
  }
}

class ContractFakeDataSource implements ContractRemoteDataSource {
  ContractFakeDataSource(this._fake);
  final FakeBackend _fake;

  @override
  Future<VehicleContract?> contract() async {
    await _fake.latency(0.5);
    final now = DateTime.now();
    return VehicleContract(
      status: 'ACTIF',
      total: 600000,
      paid: 150000,
      remaining: 450000,
      unpaidCount: 0,
      blocked: false,
      byRevenue: false,
      nextDueDate: now.add(const Duration(days: 4)),
      nextAmount: 25000,
      installments: [
        for (var i = 1; i <= 6; i++)
          Installment(
            number: i,
            dueDate: now.add(Duration(days: 7 * (i - 4))),
            amount: 25000,
            paid: i <= 3 ? 25000 : 0,
            state: i <= 3 ? InstallmentState.paid : InstallmentState.pending,
          ),
      ],
    );
  }
}
