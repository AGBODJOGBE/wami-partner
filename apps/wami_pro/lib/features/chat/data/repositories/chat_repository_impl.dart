import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_data_sources.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._remote);
  final ChatRemoteDataSource _remote;

  @override
  Stream<ChatEvent> open(String threadId) => _remote.open(threadId);

  @override
  void send(String threadId, String content) => _remote.send(threadId, content);

  @override
  void markRead(String threadId) => _remote.markRead(threadId);

  @override
  void leave() => _remote.leave();
}
