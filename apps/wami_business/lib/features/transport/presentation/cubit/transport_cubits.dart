import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/data_state.dart';
import '../../domain/entities/transport.dart';
import '../../domain/usecases/transport_usecases.dart';

class DeparturesCubit extends Cubit<DataState<List<Departure>>> {
  DeparturesCubit(this._get, this._delay) : super(const DataState());
  final GetDepartures _get;
  final ReportDelay _delay;
  late String _establishmentId;

  Future<void> load(String establishmentId) async {
    _establishmentId = establishmentId;
    await reload();
  }

  Future<void> reload() async {
    emit(state.loading());
    emit(state.apply(await _get(DeparturesParams(_establishmentId, DateTime.now()))));
  }

  Future<void> reportDelay(Departure d, int minutes) async {
    final list = state.data ?? const <Departure>[];
    emit(state.working());
    final r = await _delay(DelayParams(d, minutes));
    r.fold(
      (f) => emit(state.failed(f)),
      (saved) => emit(state.ready([for (final x in list) x.id == saved.id ? saved : x])),
    );
  }
}

/// Plan des places d'un départ : vente au guichet, blocage, embarquement.
class SeatMapCubit extends Cubit<DataState<Departure>> {
  SeatMapCubit({
    required GetDeparture getDeparture,
    required SellSeat sell,
    required ToggleSeatBlocked toggleBlocked,
    required BoardPassenger board,
  })  : _getDeparture = getDeparture,
        _sell = sell,
        _toggleBlocked = toggleBlocked,
        _board = board,
        super(const DataState());

  final GetDeparture _getDeparture;
  final SellSeat _sell;
  final ToggleSeatBlocked _toggleBlocked;
  final BoardPassenger _board;
  late String _departureId;

  Future<void> load(String departureId) async {
    _departureId = departureId;
    await reload();
  }

  Future<void> reload() async {
    emit(state.loading());
    emit(state.apply(await _getDeparture(_departureId)));
  }

  Future<bool> sell(int seat, String passengerName) async {
    final d = state.data;
    if (d == null) return false;
    emit(state.working());
    final r = await _sell(SellSeatParams(d, seat, passengerName));
    emit(state.apply(r));
    // Place prise entre-temps : on relit le plan pour afficher l'état réel.
    if (r case Err(failure: UnavailableFailure())) await _silentReload();
    return r.isOk;
  }

  Future<void> toggleBlocked(int seat) async {
    final d = state.data;
    if (d == null) return;
    emit(state.working());
    emit(state.apply(await _toggleBlocked(BlockSeatParams(d, seat))));
  }

  /// Renvoie la place du voyageur embarqué, ou `null` (l'erreur est dans l'état).
  Future<Seat?> board(String ticketCode) async {
    final d = state.data;
    if (d == null) return null;
    emit(state.working());
    final r = await _board(BoardParams(d, ticketCode, now: DateTime.now()));
    return r.fold<Seat?>(
      (f) {
        emit(state.failed(f));
        return null;
      },
      (seat) {
        emit(state.ready(d.copyWith(seats: [for (final s in d.seats) s.number == seat.number ? seat : s])));
        return seat;
      },
    );
  }

  Future<void> _silentReload() async {
    final r = await _getDeparture(_departureId);
    if (r case Ok(:final value)) emit(DataState(status: LoadStatus.ready, data: value, failure: state.failure));
  }
}

class LinesCubit extends Cubit<DataState<List<BusLine>>> {
  LinesCubit(this._get, this._updatePrice) : super(const DataState());
  final GetLines _get;
  final UpdateLinePrice _updatePrice;

  Future<void> load(String establishmentId) async {
    emit(state.loading());
    emit(state.apply(await _get(establishmentId)));
  }

  Future<void> updatePrice(BusLine line, int price) async {
    final list = state.data ?? const <BusLine>[];
    emit(state.working());
    final r = await _updatePrice(LinePriceParams(line, price));
    r.fold(
      (f) => emit(state.failed(f)),
      (saved) => emit(state.ready([for (final x in list) x.id == saved.id ? saved : x])),
    );
  }
}
