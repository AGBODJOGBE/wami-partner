import 'package:wami_core/wami_core.dart';

import '../../domain/entities/review.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../datasources/reviews_data_sources.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  const ReviewsRepositoryImpl(this._remote);
  final ReviewsRemoteDataSource _remote;

  @override
  Future<Result<List<Review>>> getReviews(String establishmentId) => guard(() => _remote.reviews(establishmentId));

  @override
  Future<Result<Review>> reply(String reviewId, String text) => guard(() => _remote.reply(reviewId, text));
}
