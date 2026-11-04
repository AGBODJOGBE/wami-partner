import 'package:wami_core/wami_core.dart';

import '../entities/review.dart';
import '../repositories/reviews_repository.dart';

class GetReviews implements UseCase<ReviewsSummary, String> {
  const GetReviews(this._repo);
  final ReviewsRepository _repo;

  @override
  Future<Result<ReviewsSummary>> call(String establishmentId) async =>
      (await _repo.getReviews(establishmentId)).map(ReviewsSummary.new);
}

class ReplyParams {
  const ReplyParams(this.review, this.text);
  final Review review;
  final String text;
}

/// Une seule réponse publique par avis (modifiable plus tard : à valider).
class ReplyToReview implements UseCase<Review, ReplyParams> {
  const ReplyToReview(this._repo);
  final ReviewsRepository _repo;

  @override
  Future<Result<Review>> call(ReplyParams p) async {
    final text = p.text.trim();
    if (p.review.answered) return const Err(ValidationFailure('Vous avez déjà répondu à cet avis.'));
    if (text.length < ReplyRules.minLength) return const Err(ValidationFailure('Écrivez votre réponse.'));
    if (text.length > ReplyRules.maxLength) return const Err(ValidationFailure('${ReplyRules.maxLength} caractères maximum.'));
    return _repo.reply(p.review.id, text);
  }
}
