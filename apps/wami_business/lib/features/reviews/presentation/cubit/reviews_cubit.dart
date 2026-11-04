import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/data_state.dart';
import '../../domain/entities/review.dart';
import '../../domain/usecases/reviews_usecases.dart';

class ReviewsCubit extends Cubit<DataState<ReviewsSummary>> {
  ReviewsCubit(this._get, this._reply) : super(const DataState());
  final GetReviews _get;
  final ReplyToReview _reply;

  Future<void> load(String establishmentId) async {
    emit(state.loading());
    emit(state.apply(await _get(establishmentId)));
  }

  Future<bool> reply(Review review, String text) async {
    final d = state.data;
    if (d == null) return false;
    emit(state.working());
    final r = await _reply(ReplyParams(review, text));
    r.fold(
      (f) => emit(state.failed(f)),
      (saved) => emit(state.ready(ReviewsSummary([for (final x in d.reviews) x.id == saved.id ? saved : x]))),
    );
    return r.isOk;
  }
}
