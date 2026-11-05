import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:wami_core/wami_core.dart';

import 'session_store.dart';

/// Connexion Socket.io au serveur (même hôte que l'API).
///
/// Reçoit : `ride:new_request`, `delivery_b2c:new_request`, `ride:cancelled`.
/// Émet : `driver:heartbeat` (présence, expire après 90 s) et `ride:gps`.
/// Le serveur rejoue la dernière offre à chaque (re)connexion (`isReplay`).
class RealtimeClient {
  RealtimeClient(this._config, this._session);

  final AppConfig _config;
  final SessionStore _session;
  io.Socket? _socket;

  final _rideRequests = StreamController<Map<String, dynamic>>.broadcast();
  final _deliveryRequests = StreamController<Map<String, dynamic>>.broadcast();
  final _cancelled = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get rideRequests => _rideRequests.stream;
  Stream<Map<String, dynamic>> get deliveryRequests => _deliveryRequests.stream;
  Stream<Map<String, dynamic>> get cancellations => _cancelled.stream;

  bool get connected => _socket?.connected ?? false;

  final _extra = <String, StreamController<dynamic>>{};

  /// Flux d'un événement quelconque (chat, changement de destination, densité…).
  /// Branché sur le socket dès qu'il est ouvert, même si l'écoute commence avant `connect()`.
  Stream<dynamic> on(String event) {
    final existing = _extra[event];
    if (existing != null) return existing.stream;
    final sink = StreamController<dynamic>.broadcast();
    _extra[event] = sink;
    _socket?.on(event, sink.add);
    return sink.stream;
  }

  void emit(String event, [dynamic data]) => _socket?.emit(event, data);

  void connect() {
    final token = _session.identity?.token;
    if (token == null || _socket != null) return;
    final socket = io.io(
      _config.apiBaseUrl,
      io.OptionBuilder().setTransports(['websocket']).setAuth({'token': token}).enableReconnection().build(),
    );
    void forward(String event, StreamController<Map<String, dynamic>> sink) {
      socket.on(event, (data) {
        if (data is Map) sink.add(Map<String, dynamic>.from(data));
      });
    }

    forward('ride:new_request', _rideRequests);
    forward('delivery_b2c:new_request', _deliveryRequests);
    forward('ride:cancelled', _cancelled);
    for (final e in _extra.entries) {
      socket.on(e.key, e.value.add);
    }
    _socket = socket;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void heartbeat(double lat, double lng) => _socket?.emit('driver:heartbeat', {'latitude': lat, 'longitude': lng});

  /// Position pendant une course ; pour une livraison, `id` est l'identifiant de commande.
  void gps(String id, {required double lat, required double lng, double? heading, double? speed, double? accuracy}) {
    _socket?.emit('ride:gps', {
      'rideId': id,
      'latitude': lat,
      'longitude': lng,
      'heading': heading ?? 0,
      'speed': speed ?? 0,
      'accuracy': accuracy ?? 0,
      'deviceTimestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void joinRide(String rideId) => _socket?.emit('ride:driver:join', rideId);
  void joinOrder(String orderId) => _socket?.emit('order:driver:join', orderId);
}
