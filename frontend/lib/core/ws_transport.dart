import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Minimal socket abstraction so the client can be tested without a server.
abstract class WsTransport {
  /// Completes when the socket is open.
  Future<void> connect();

  /// Text frames from the server; closes when the socket closes.
  Stream<String> get messages;

  void send(String data);

  Future<void> close([int code = 1000, String? reason]);

  /// Close code once [messages] is done (null when unknown).
  int? get closeCode;

  String? get closeReason;
}

/// Creates a transport for a URL.
typedef TransportFactory = WsTransport Function(Uri url);

/// Production transport over `web_socket_channel`.
class ChannelTransport implements WsTransport {
  ChannelTransport(this.url);

  final Uri url;
  WebSocketChannel? _channel;

  @override
  Future<void> connect() async {
    final channel = WebSocketChannel.connect(url);
    _channel = channel;
    await channel.ready;
  }

  @override
  Stream<String> get messages => _channel!.stream.map(
    (data) => data is String ? data : String.fromCharCodes(data as List<int>),
  );

  @override
  void send(String data) => _channel?.sink.add(data);

  @override
  Future<void> close([int code = 1000, String? reason]) async {
    await _channel?.sink.close(code, reason);
  }

  @override
  int? get closeCode => _channel?.closeCode;

  @override
  String? get closeReason => _channel?.closeReason;
}
