import 'dart:async';

import 'package:wami_core/wami_core.dart';

import '../../../../shared/realtime_client.dart';
import '../../domain/entities/chat_message.dart';

abstract interface class ChatRemoteDataSource {
  Stream<ChatEvent> open(String threadId);
  void send(String threadId, String content);
  void markRead(String threadId);
  void leave();
}

ChatMessage _message(Map<dynamic, dynamic> m) => ChatMessage(
      id: '${m['id']}',
      content: (m['content'] as String?) ?? '',
      sentAt: DateTime.tryParse('${m['sentAt']}')?.toLocal() ?? DateTime.now(),
      mine: m['senderRole'] == 'DRIVER',
    );

/// Chat 100 % Socket.IO (aucune route REST).
///
/// Prérequis côté serveur : le chauffeur doit avoir rejoint la salle de la course
/// (`ride:driver:join`) ou de la commande (`order:driver:join`), ce que fait la source des
/// missions à l'acceptation. `chat:message` n'a pas de `threadId` : un seul fil est ouvert à la fois.
class ChatSocketDataSource implements ChatRemoteDataSource {
  ChatSocketDataSource(this._rt);
  final RealtimeClient _rt;

  final _subs = <StreamSubscription<dynamic>>[];
  StreamController<ChatEvent>? _out;

  @override
  Stream<ChatEvent> open(String threadId) {
    leave();
    final out = _out = StreamController<ChatEvent>();
    _subs
      ..add(_rt.on('chat:history').listen((d) {
        if (d is! Map) return;
        final list = (d['messages'] as List<dynamic>? ?? const []).whereType<Map>().map(_message).toList();
        out.add(ChatHistory(list));
      }))
      ..add(_rt.on('chat:message').listen((d) {
        if (d is Map) out.add(ChatIncoming(_message(d)));
      }))
      ..add(_rt.on('chat:closed').listen((_) => out.add(const ChatClosed())))
      ..add(_rt.on('chat:error').listen((d) {
        out.add(ChatFailed(d is Map ? '${d['message']}' : 'Le chat est indisponible.'));
      }));
    _rt.emit('chat:join', threadId);
    return out.stream;
  }

  @override
  void send(String threadId, String content) => _rt.emit('chat:send', {'threadId': threadId, 'content': content});

  @override
  void markRead(String threadId) => _rt.emit('chat:read', threadId);

  @override
  void leave() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _out?.close();
    _out = null;
  }
}

class ChatFakeDataSource implements ChatRemoteDataSource {
  ChatFakeDataSource(this._fake);
  final FakeBackend _fake;

  StreamController<ChatEvent>? _out;

  @override
  Stream<ChatEvent> open(String threadId) {
    _out?.close();
    final out = _out = StreamController<ChatEvent>();
    Future<void>.microtask(() => out.add(const ChatHistory([])));
    return out.stream;
  }

  @override
  void send(String threadId, String content) {
    _out?.add(ChatIncoming(ChatMessage(id: '${DateTime.now().microsecondsSinceEpoch}', content: content, sentAt: DateTime.now(), mine: true)));
    Future<void>.delayed(const Duration(seconds: 1), () {
      _out?.add(ChatIncoming(ChatMessage(id: 'r${DateTime.now().microsecondsSinceEpoch}', content: 'D’accord, merci !', sentAt: DateTime.now(), mine: false)));
    });
  }

  @override
  void markRead(String threadId) {}

  @override
  void leave() {
    _out?.close();
    _out = null;
  }
}
