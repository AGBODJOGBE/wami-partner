import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../../../shared/data_state.dart';
import '../../domain/entities/rental.dart';
import '../../domain/usecases/rental_usecases.dart';

class VisitsData extends Equatable {
  const VisitsData(this.visits, this.windows);
  final List<VisitRequest> visits;
  final List<AvailabilityWindow> windows;

  List<VisitRequest> get pending => visits.where((v) => v.status == VisitStatus.pending).toList();

  List<VisitRequest> upcoming(DateTime now) => visits
      .where((v) => (v.status == VisitStatus.accepted || v.status == VisitStatus.proposed) && v.slot.isAfter(now))
      .toList()
    ..sort((a, b) => a.slot.compareTo(b.slot));

  @override
  List<Object?> get props => [visits, windows];
}

/// Demandes de visite : accepter, refuser, proposer un autre créneau.
class VisitsCubit extends Cubit<DataState<VisitsData>> {
  VisitsCubit({
    required GetVisits getVisits,
    required GetAvailability getAvailability,
    required AcceptVisit accept,
    required DeclineVisit decline,
    required ProposeVisitSlot propose,
  })  : _getVisits = getVisits,
        _getAvailability = getAvailability,
        _accept = accept,
        _decline = decline,
        _propose = propose,
        super(const DataState());

  final GetVisits _getVisits;
  final GetAvailability _getAvailability;
  final AcceptVisit _accept;
  final DeclineVisit _decline;
  final ProposeVisitSlot _propose;
  late String _establishmentId;

  Future<void> load(String establishmentId) async {
    _establishmentId = establishmentId;
    await reload();
  }

  Future<void> reload() async {
    emit(state.loading());
    final visits = await _getVisits(_establishmentId);
    final windows = await _getAvailability(_establishmentId);
    switch ((visits, windows)) {
      case (Ok(value: final v), Ok(value: final w)):
        emit(state.ready(VisitsData(v, w)));
      case (Err(:final failure), _) || (_, Err(:final failure)):
        emit(state.failed(failure));
    }
  }

  Future<void> accept(VisitRequest v) => _act(_accept(v));
  Future<void> decline(VisitRequest v) => _act(_decline(v));

  Future<void> propose(VisitRequest v, DateTime slot) {
    final d = state.data;
    return _act(_propose(ProposeVisitParams(visit: v, slot: slot, windows: d?.windows ?? const [], now: DateTime.now())));
  }

  Future<void> _act(Future<Result<VisitRequest>> action) async {
    final d = state.data;
    if (d == null) return;
    emit(state.working());
    final r = await action;
    r.fold(
      (f) => emit(state.failed(f)),
      (v) => emit(state.ready(VisitsData([for (final x in d.visits) x.id == v.id ? v : x], d.windows))),
    );
  }
}

class ListingsData extends Equatable {
  const ListingsData(this.listings, this.windows);
  final List<Listing> listings;
  final List<AvailabilityWindow> windows;

  @override
  List<Object?> get props => [listings, windows];
}

/// Biens à louer et disponibilités de visite.
class ListingsCubit extends Cubit<DataState<ListingsData>> {
  ListingsCubit({
    required GetListings getListings,
    required GetAvailability getAvailability,
    required SetListingRented setRented,
    required SaveAvailability saveAvailability,
  })  : _getListings = getListings,
        _getAvailability = getAvailability,
        _setRented = setRented,
        _saveAvailability = saveAvailability,
        super(const DataState());

  final GetListings _getListings;
  final GetAvailability _getAvailability;
  final SetListingRented _setRented;
  final SaveAvailability _saveAvailability;
  late String _establishmentId;

  Future<void> load(String establishmentId) async {
    _establishmentId = establishmentId;
    emit(state.loading());
    final listings = await _getListings(establishmentId);
    final windows = await _getAvailability(establishmentId);
    switch ((listings, windows)) {
      case (Ok(value: final l), Ok(value: final w)):
        emit(state.ready(ListingsData(l, w)));
      case (Err(:final failure), _) || (_, Err(:final failure)):
        emit(state.failed(failure));
    }
  }

  Future<void> toggleRented(Listing l) async {
    final d = state.data;
    if (d == null) return;
    emit(state.working());
    final r = await _setRented(l);
    r.fold(
      (f) => emit(state.failed(f)),
      (saved) => emit(state.ready(ListingsData([for (final x in d.listings) x.id == saved.id ? saved : x], d.windows))),
    );
  }

  Future<bool> addWindow(AvailabilityWindow w) {
    final d = state.data;
    return _saveWindows([...?d?.windows, w]);
  }

  Future<bool> removeWindow(AvailabilityWindow w) {
    final d = state.data;
    return _saveWindows([...?d?.windows.where((x) => x != w)]);
  }

  Future<bool> _saveWindows(List<AvailabilityWindow> windows) async {
    final d = state.data;
    if (d == null) return false;
    emit(state.working());
    final r = await _saveAvailability(SaveAvailabilityParams(_establishmentId, windows));
    r.fold(
      (f) => emit(state.failed(f)),
      (saved) => emit(state.ready(ListingsData(d.listings, saved))),
    );
    return r.isOk;
  }
}
