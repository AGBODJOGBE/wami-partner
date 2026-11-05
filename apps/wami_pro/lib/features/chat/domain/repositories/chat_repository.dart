import '../entities/chat_message.dart';

abstract interface class ChatRepository {
  /// Ouvre le fil : l'historique arrive d'abord, puis les messages. Le flux se ferme avec [ChatClosed].
  Stream<ChatEvent> open(String threadId);

  void send(String threadId, String content);
  void markRead(String threadId);
  void leave();
}
