import 'package:wami_core/wami_core.dart';

import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Identifiant du fil d'une mission, tel que le serveur le calcule : `ride:{id}` ou `b2c-order:{id}`.
String chatThreadId({required String missionId, required bool isDelivery}) =>
    isDelivery ? 'b2c-order:$missionId' : 'ride:$missionId';

class OpenChat implements StreamUseCase<ChatEvent, String> {
  const OpenChat(this._repo);
  final ChatRepository _repo;

  @override
  Stream<ChatEvent> call(String threadId) => _repo.open(threadId);
}

class SendParams {
  const SendParams({required this.threadId, required this.content});
  final String threadId;
  final String content;
}

class SendChatMessage {
  const SendChatMessage(this._repo);
  final ChatRepository _repo;

  /// Message non vide, 500 caractères au plus (limite du serveur).
  Failure? call(SendParams p) {
    final text = p.content.trim();
    if (text.isEmpty) return const ValidationFailure('Écrivez un message.');
    if (text.length > 500) return const ValidationFailure('Message trop long (500 caractères au plus).');
    _repo.send(p.threadId, text);
    return null;
  }
}

class MarkChatRead {
  const MarkChatRead(this._repo);
  final ChatRepository _repo;

  void call(String threadId) => _repo.markRead(threadId);
}

class LeaveChat {
  const LeaveChat(this._repo);
  final ChatRepository _repo;

  void call() => _repo.leave();
}
