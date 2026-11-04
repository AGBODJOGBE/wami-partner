import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wami_core/wami_core.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/chat_usecases.dart';

class ChatState extends Equatable {
  const ChatState({this.messages = const [], this.loading = true, this.closed = false, this.failure});
  final List<ChatMessage> messages;
  final bool loading;

  /// La course ou la livraison est terminée : le fil est supprimé côté serveur.
  final bool closed;
  final Failure? failure;

  @override
  List<Object?> get props => [messages, loading, closed, failure];
}

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._open, this._send, this._read, this._leave, this.threadId) : super(const ChatState());
  final OpenChat _open;
  final SendChatMessage _send;
  final MarkChatRead _read;
  final LeaveChat _leave;
  final String threadId;
  StreamSubscription<ChatEvent>? _sub;

  void start() {
    _sub = _open(threadId).listen((e) {
      switch (e) {
        case ChatHistory(:final messages):
          emit(ChatState(messages: messages, loading: false));
          _read(threadId);
        case ChatIncoming(:final message):
          // Le serveur renvoie aussi nos propres messages (accusé) : pas de doublon.
          if (state.messages.any((m) => m.id == message.id)) return;
          emit(ChatState(messages: [...state.messages, message], loading: false));
          if (!message.mine) _read(threadId);
        case ChatClosed():
          emit(ChatState(messages: state.messages, loading: false, closed: true));
        case ChatFailed(:final message):
          emit(ChatState(messages: state.messages, loading: false, failure: ValidationFailure(message)));
      }
    });
  }

  void send(String text) {
    final f = _send(SendParams(threadId: threadId, content: text));
    if (f != null) emit(ChatState(messages: state.messages, loading: false, failure: f));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _leave();
    return super.close();
  }
}
