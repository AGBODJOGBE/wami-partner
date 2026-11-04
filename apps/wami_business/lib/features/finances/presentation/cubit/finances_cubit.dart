import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/data_state.dart';
import '../../domain/entities/finances.dart';
import '../../domain/usecases/finances_usecases.dart';

class FinancesCubit extends Cubit<DataState<FinanceOverview>> {
  FinancesCubit(this._get) : super(const DataState());
  final GetFinanceOverview _get;

  Future<void> load(String establishmentId) async {
    emit(state.loading());
    emit(state.apply(await _get(establishmentId)));
  }
}
