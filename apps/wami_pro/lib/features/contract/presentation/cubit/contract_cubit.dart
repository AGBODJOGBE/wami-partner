import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/data_state.dart';
import '../../domain/entities/contract.dart';
import '../../domain/usecases/contract_usecases.dart';

/// `data == null` avec `status == ready` : aucun contrat.
class ContractCubit extends Cubit<DataState<VehicleContract>> {
  ContractCubit(this._get) : super(const DataState());
  final GetContract _get;

  Future<void> load() async {
    emit(const DataState(status: LoadStatus.loading));
    final r = await _get(const NoParams());
    emit(r.fold(
      (f) => DataState(status: LoadStatus.failure, failure: f),
      (c) => DataState(status: LoadStatus.ready, data: c),
    ));
  }
}
