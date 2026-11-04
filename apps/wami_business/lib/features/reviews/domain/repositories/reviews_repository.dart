import 'package:wami_core/wami_core.dart';

import '../entities/review.dart';

abstract interface class ReviewsRepository {
  Future<Result<List<Review>>> getReviews(String establishmentId);
  Future<Result<Review>> reply(String reviewId, String text);
}
