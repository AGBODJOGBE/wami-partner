import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({required this.id, required this.content, required this.sentAt, required this.mine});
  final String id;
  final String content;
  final DateTime sentAt;

  /// Écrit par le chauffeur.
  final bool mine;

  @override
  List<Object?> get props => [id, content, sentAt, mine];
}

/// Événement du fil : message reçu, ou fil fermé (course terminée ou annulée).
sealed class ChatEvent {
  const ChatEvent();
}

final class ChatHistory extends ChatEvent {
  const ChatHistory(this.messages);
  final List<ChatMessage> messages;
}

final class ChatIncoming extends ChatEvent {
  const ChatIncoming(this.message);
  final ChatMessage message;
}

final class ChatClosed extends ChatEvent {
  const ChatClosed();
}

final class ChatFailed extends ChatEvent {
  const ChatFailed(this.message);
  final String message;
}
