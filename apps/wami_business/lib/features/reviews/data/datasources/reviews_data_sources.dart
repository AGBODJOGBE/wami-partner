import 'package:wami_core/wami_core.dart';

import '../../domain/entities/review.dart';

abstract interface class ReviewsRemoteDataSource {
  Future<List<Review>> reviews(String establishmentId);
  Future<Review> reply(String reviewId, String text);
}

Review _review(Map<String, dynamic> j) => Review(
      id: j['id'] as String,
      author: j['author'] as String,
      rating: j['rating'] as int,
      text: j['text'] as String,
      date: DateTime.parse(j['date'] as String),
      reply: j['reply'] as String?,
    );

/// Endpoints à valider.
class ReviewsApiDataSource implements ReviewsRemoteDataSource {
  const ReviewsApiDataSource(this._api);
  final ApiClient _api;

  @override
  Future<List<Review>> reviews(String establishmentId) async {
    final j = await _api.get('/v1/business/establishments/$establishmentId/reviews');
    return [for (final r in (j['items'] as List<dynamic>).cast<Map<String, dynamic>>()) _review(r)];
  }

  @override
  Future<Review> reply(String reviewId, String text) async =>
      _review(await _api.post('/v1/business/reviews/$reviewId/reply', body: {'text': text}));
}

class ReviewsFakeDataSource implements ReviewsRemoteDataSource {
  ReviewsFakeDataSource(this._fake);
  final FakeBackend _fake;

  late final List<Review> _items = () {
    final now = DateTime.now();
    DateTime ago(int days) => now.subtract(Duration(days: days));
    return [
      Review(id: 'r1', author: 'Gisèle A.', rating: 3, text: 'Bon accueil mais attente un peu longue.', date: ago(0)),
      Review(id: 'r2', author: 'Kevin S.', rating: 5, text: 'Parfait, rien à redire. Je reviendrai.', date: ago(1)),
      Review(id: 'r3', author: 'Aminatou B.', rating: 4, text: 'Très propre, personnel souriant.', date: ago(3), reply: 'Merci Aminatou, à bientôt !'),
      Review(id: 'r4', author: 'Serge D.', rating: 2, text: 'La climatisation ne marchait pas.', date: ago(6)),
    ];
  }();

  @override
  Future<List<Review>> reviews(String establishmentId) async {
    await _fake.latency(0.5);
    return List.of(_items);
  }

  @override
  Future<Review> reply(String reviewId, String text) async {
    await _fake.latency(0.5);
    final i = _items.indexWhere((r) => r.id == reviewId);
    if (i < 0) throw const BusinessRuleException('unavailable');
    return _items[i] = _items[i].copyWith(reply: text);
  }
}
