import 'package:equatable/equatable.dart';

class Review extends Equatable {
  const Review({
    required this.id,
    required this.author,
    required this.rating,
    required this.text,
    required this.date,
    this.reply,
  });

  final String id;
  final String author;
  final int rating;
  final String text;
  final DateTime date;

  /// Réponse publique de l'établissement.
  final String? reply;

  bool get answered => reply != null;

  Review copyWith({String? reply}) => Review(id: id, author: author, rating: rating, text: text, date: date, reply: reply ?? this.reply);

  @override
  List<Object?> get props => [id, author, rating, text, date, reply];
}

class ReviewsSummary extends Equatable {
  const ReviewsSummary(this.reviews);
  final List<Review> reviews;

  double get average => reviews.isEmpty ? 0 : reviews.fold(0, (s, r) => s + r.rating) / reviews.length;
  int get unanswered => reviews.where((r) => !r.answered).length;

  /// Nombre d'avis par note, de 5 à 1.
  List<int> get distribution => [for (var n = 5; n >= 1; n--) reviews.where((r) => r.rating == n).length];

  @override
  List<Object?> get props => [reviews];
}

abstract final class ReplyRules {
  static const minLength = 2;
  static const maxLength = 500;
}
