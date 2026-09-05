import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../protocol/protocol.dart';
import 'ws_transport.dart';

/// Connection states of [WsClient].
enum WsStatus { disconnected, connecting, helloSent, ready }

/// Observable connection state.
class WsState {
  const WsState({
    this.status = WsStatus.disconnected,
    this.attempt = 0,
    this.closeCode,
    this.closeReason,
    this.terminal = false,
  });

  final WsStatus status;

  /// Reconnect attempts since the last successful hello (0 while connected).
  final int attempt;
  final int? closeCode;
  final String? closeReason;

  /// True when the server closed with a code that forbids reconnecting.
  final bool terminal;

  WsState copyWith({
    WsStatus? status,
    int? attempt,
    int? closeCode,
    String? closeReason,
    bool? terminal,
  }) => WsState(
    status: status ?? this.status,
    attempt: attempt ?? this.attempt,
    closeCode: closeCode ?? this.closeCode,
    closeReason: closeReason ?? this.closeReason,
    terminal: terminal ?? this.terminal,
  );
}

/// Error reply to a command.
class ServerError implements Exception {
  const ServerError(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'ServerError($code: $message)';
}

/// The game connection: hello handshake, command/ack correlation, heartbeat
/// pings for time sync, and reconnection with exponential backoff
/// (0.5 s → 10 s with jitter).
class WsClient {
  WsClient({
    required this.url,
    required this.token,
    this.adminToken,
    TransportFactory? transportFactory,
    this.pingInterval = const Duration(seconds: 15),
    this.minBackoff = const Duration(milliseconds: 500),
    this.maxBackoff = const Duration(seconds: 10),
    Random? random,
  }) : _factory = transportFactory ?? ChannelTransport.new,
       _random = random ?? Random();

  final Uri url;
  final String token;

  /// The table's admin token, sent alongside the session token so the server
  /// flags this connection as the table admin.
  final String? adminToken;
  final Duration pingInterval;
  final Duration minBackoff;
  final Duration maxBackoff;
  final TransportFactory _factory;
  final Random _random;

  final _messages = StreamController<ServerMessage>.broadcast();
  final _states = StreamController<WsState>.broadcast();
  final _pending = <String, Completer<void>>{};

  WsState _state = const WsState();
  WsTransport? _transport;
  StreamSubscription<String>? _sub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _seq = 0;
  bool _disposed = false;
  int _generation = 0;

  Stream<ServerMessage> get messages => _messages.stream;
  Stream<WsState> get states => _states.stream;
  WsState get state => _state;

  void _setState(WsState s) {
    _state = s;
    if (!_states.isClosed) {
      _states.add(s);
    }
  }

  /// Opens the connection (idempotent).
  void connect() {
    if (_disposed ||
        _state.status != WsStatus.disconnected ||
        _state.terminal) {
      return;
    }
    _reconnectTimer?.cancel();
    _open();
  }

  Future<void> _open() async {
    final gen = ++_generation;
    _setState(
      _state.copyWith(
        status: WsStatus.connecting,
        closeCode: null,
        closeReason: null,
      ),
    );
    final transport = _factory(url);
    _transport = transport;
    try {
      await transport.connect();
    } catch (e) {
      if (gen != _generation) return;
      _onClosed(null, 'connect failed: $e');
      return;
    }
    if (gen != _generation) return;
    _sub = transport.messages.listen(
      _onData,
      onError: (Object e) => _onClosed(transport.closeCode, e.toString()),
      onDone: () => _onClosed(transport.closeCode, transport.closeReason),
      cancelOnError: true,
    );
    _sendEnvelope(
      encodeClientMessage(
        ClientMessage.hello(
          Hello(v: protocolVersion, token: token, adminToken: adminToken),
        ),
      ),
    );
    _setState(_state.copyWith(status: WsStatus.helloSent));
  }

  void _onData(String data) {
    final ServerMessage msg;
    try {
      msg = decodeServerMessage(
        Envelope.fromJson(jsonDecode(data) as Map<String, dynamic>),
      );
    } on ProtocolError catch (e) {
      // Unknown or malformed message: the server is authoritative, skip it.
      debugPrint('ws: dropped message: $e');
      return;
    } on FormatException {
      return;
    }
    switch (msg) {
      case WelcomeMessage():
        _setState(const WsState(status: WsStatus.ready));
        _startPing();
      case AckMessage(:final payload):
        _pending.remove(payload.id)?.complete();
      case ErrorMessage(:final payload):
        final id = payload.id;
        if (id != null) {
          _pending
              .remove(id)
              ?.completeError(ServerError(payload.code, payload.message));
        }
      default:
        break;
    }
    if (!_messages.isClosed) _messages.add(msg);
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) {
      if (_state.status == WsStatus.ready) {
        _sendEnvelope(
          encodeClientMessage(const ClientMessage.ping(), id: _nextId()),
        );
      }
    });
  }

  void _onClosed(int? code, String? reason) {
    _pingTimer?.cancel();
    _sub?.cancel();
    _sub = null;
    _transport = null;
    for (final c in _pending.values) {
      c.completeError(const ServerError('disconnected', 'connection lost'));
    }
    _pending.clear();
    if (_disposed) return;
    final terminal = CloseCodes.isTerminal(code);
    final attempt = _state.attempt + 1;
    _setState(
      WsState(
        status: WsStatus.disconnected,
        attempt: terminal ? 0 : attempt,
        closeCode: code,
        closeReason: reason,
        terminal: terminal,
      ),
    );
    if (terminal) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(backoffFor(attempt), () {
      if (_state.status == WsStatus.disconnected && !_state.terminal) _open();
    });
  }

  /// Backoff for the n-th attempt: 0.5 s doubling to 10 s, ±25 % jitter.
  Duration backoffFor(int attempt) {
    final base = min(
      minBackoff.inMilliseconds * pow(2, max(0, attempt - 1)).toDouble(),
      maxBackoff.inMilliseconds.toDouble(),
    );
    final jitter = base * 0.25 * (_random.nextDouble() * 2 - 1);
    return Duration(milliseconds: (base + jitter).round());
  }

  String _nextId() => 'c-${++_seq}';

  void _sendEnvelope(Envelope env) {
    _transport?.send(jsonEncode(env.toJson()));
  }

  /// Sends a command; completes on ack, fails with [ServerError] on error.
  Future<void> send(ClientMessage msg) {
    if (_state.status != WsStatus.ready) {
      return Future.error(const ServerError('disconnected', 'not connected'));
    }
    final id = _nextId();
    final completer = Completer<void>();
    _pending[id] = completer;
    _sendEnvelope(encodeClientMessage(msg, id: id));
    return completer.future;
  }

  /// Reconnects now after a terminal close (e.g. take the seat back after 4004).
  void reconnectNow() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _setState(const WsState());
    _open();
  }

  Future<void> dispose() async {
    _disposed = true;
    _generation++;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await _sub?.cancel();
    await _transport?.close();
    _transport = null;
    await _messages.close();
    await _states.close();
  }
}
