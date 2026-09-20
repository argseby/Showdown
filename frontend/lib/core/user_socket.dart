import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account.dart';
import 'config.dart';
import 'friends.dart';
import 'ws_transport.dart';

/// What a user event can be about (see docs/protocol.md).
class UserEventKind {
  static const friendRequest = 'friend_request';
  static const friendAccepted = 'friend_accepted';
  static const friendsChanged = 'friends_changed';
  static const tableInvite = 'table_invite';
  static const friendsPlaying = 'friends_playing';
}

/// One push from the user socket: something happened to the person, not to
/// the table they are sitting at.
class UserEvent {
  const UserEvent({
    required this.kind,
    this.handle = '',
    this.displayName = '',
    this.inviteId = '',
    this.tableId = '',
    this.tableName = '',
    this.at = 0,
  });

  factory UserEvent.fromJson(Map<String, dynamic> json) => UserEvent(
    kind: json['kind'] as String? ?? '',
    handle: json['handle'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '',
    inviteId: json['invite_id'] as String? ?? '',
    tableId: json['table_id'] as String? ?? '',
    tableName: json['table_name'] as String? ?? '',
    at: (json['at'] as num?)?.toInt() ?? 0,
  );

  final String kind;
  final String handle;
  final String displayName;
  final String inviteId;
  final String tableId;
  final String tableName;
  final int at;

  /// The name to show: what they call themselves, else the handle.
  String get name => displayName.isNotEmpty ? displayName : handle;
}

/// The user socket: one connection per device for the signed-in profile,
/// carrying what happens away from the table. It sends nothing but the
/// hello and the odd ping, so there is nothing to get wrong on the way
/// out; everything it announces can also be read over REST.
class UserSocket {
  UserSocket({
    required this.url,
    required this.token,
    TransportFactory? transportFactory,
  }) : _factory = transportFactory ?? ChannelTransport.new;

  final Uri url;
  final String token;
  final TransportFactory _factory;

  final _events = StreamController<UserEvent>.broadcast();
  Stream<UserEvent> get events => _events.stream;

  WsTransport? _transport;
  StreamSubscription<String>? _sub;
  Timer? _retry;
  int _attempt = 0;
  bool _disposed = false;

  /// Whether the socket is carrying events right now.
  bool get connected => _transport != null && _sub != null;

  Future<void> connect() async {
    if (_disposed) return;
    _retry?.cancel();
    final transport = _factory(url);
    try {
      await transport.connect();
    } catch (_) {
      _scheduleRetry();
      return;
    }
    if (_disposed) {
      await transport.close();
      return;
    }
    _transport = transport;
    _sub = transport.messages.listen(
      _onMessage,
      onDone: () => _onClosed(transport.closeCode),
      onError: (_) => _onClosed(transport.closeCode),
    );
    transport.send(
      jsonEncode({
        'type': 'hello',
        'id': 'u-hello',
        'payload': {'v': 1, 'token': token},
      }),
    );
    _attempt = 0;
  }

  void _onMessage(String data) {
    try {
      final env = jsonDecode(data) as Map<String, dynamic>;
      if (env['type'] != 'user_event') return;
      final payload = env['payload'] as Map<String, dynamic>? ?? const {};
      _events.add(UserEvent.fromJson(payload));
    } on FormatException catch (e) {
      debugPrint('user socket: $e');
    }
  }

  void _onClosed(int? code) {
    _sub?.cancel();
    _sub = null;
    _transport = null;
    // A token the server refuses will not get better by trying again; the
    // profile is signed out elsewhere and a new socket starts then.
    if (_disposed || code == 4001 || code == 4002) return;
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_disposed) return;
    _attempt++;
    final backoff = min(10000, 500 * pow(2, _attempt - 1).toInt());
    final jitter = Random().nextInt(max(1, backoff ~/ 4));
    _retry = Timer(Duration(milliseconds: backoff + jitter), connect);
  }

  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _sub?.cancel();
    _transport?.close();
    _transport = null;
    _events.close();
  }
}

/// A notification on screen: a friend asking, or a friend calling you to a
/// table. They queue up rather than replace each other, and nothing here
/// disappears on its own — each one is answered or dismissed.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.handle,
    required this.name,
    this.inviteId = '',
    this.tableId = '',
    this.tableName = '',
  });

  final String id;
  final String kind;
  final String handle;
  final String name;
  final String inviteId;
  final String tableId;
  final String tableName;
}

/// The notifications waiting to be answered, oldest first.
class NotificationsNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() => const [];

  void add(AppNotification n) {
    // The same ask twice (a reconnect, say) stays one card.
    if (state.any((o) => o.id == n.id)) return;
    state = [...state, n];
  }

  void remove(String id) {
    state = [
      for (final n in state)
        if (n.id != id) n,
    ];
  }

  void clear() => state = const [];
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<AppNotification>>(
      NotificationsNotifier.new,
    );

/// Keeps a user socket open while somebody is signed in, turns what it
/// pushes into notifications, and refreshes the lists the event points at.
class UserSocketNotifier extends Notifier<bool> {
  /// Test seam: the transport and the URL of the socket.
  static TransportFactory? transportFactoryOverride;
  static Uri? urlOverride;

  UserSocket? _socket;
  StreamSubscription<UserEvent>? _sub;

  @override
  bool build() {
    ref.onDispose(_teardown);
    final account = ref.watch(accountProvider).value;
    final token = ref.read(accountProvider.notifier).token;
    if (account == null || token == null) {
      _teardown();
      // Signing out clears what was on screen — but not while this
      // provider is still building, which Riverpod forbids.
      Future.microtask(() => ref.read(notificationsProvider.notifier).clear());
      return false;
    }
    _start(token);
    return true;
  }

  Uri _url() {
    if (urlOverride != null) return urlOverride!;
    var base = AppConfig.wsBase;
    if (base.isEmpty) {
      final origin = Uri.base;
      final scheme = origin.scheme == 'https' ? 'wss' : 'ws';
      base =
          '$scheme://${origin.host}${origin.hasPort ? ':${origin.port}' : ''}';
    }
    return Uri.parse('$base/ws/me');
  }

  void _start(String token) {
    if (_socket != null && _socket!.token == token) return;
    _teardown();
    final socket = UserSocket(
      url: _url(),
      token: token,
      transportFactory: transportFactoryOverride,
    );
    _socket = socket;
    _sub = socket.events.listen(_onEvent);
    socket.connect();
  }

  void _onEvent(UserEvent e) {
    final notifications = ref.read(notificationsProvider.notifier);
    switch (e.kind) {
      case UserEventKind.friendRequest:
        notifications.add(
          AppNotification(
            id: 'request:${e.handle}',
            kind: e.kind,
            handle: e.handle,
            name: e.name,
          ),
        );
        ref.invalidate(friendsProvider);
      case UserEventKind.tableInvite:
        notifications.add(
          AppNotification(
            id: 'invite:${e.inviteId}',
            kind: e.kind,
            handle: e.handle,
            name: e.name,
            inviteId: e.inviteId,
            tableId: e.tableId,
            tableName: e.tableName,
          ),
        );
        ref.invalidate(friendsProvider);
      case UserEventKind.friendAccepted:
        notifications.add(
          AppNotification(
            id: 'accepted:${e.handle}:${e.at}',
            kind: e.kind,
            handle: e.handle,
            name: e.name,
          ),
        );
        ref.invalidate(friendsProvider);
        ref.invalidate(friendsPlayingProvider);
      case UserEventKind.friendsChanged:
        ref.invalidate(friendsProvider);
        ref.invalidate(friendsPlayingProvider);
      case UserEventKind.friendsPlaying:
        ref.invalidate(friendsPlayingProvider);
    }
  }

  void _teardown() {
    _sub?.cancel();
    _sub = null;
    _socket?.dispose();
    _socket = null;
  }
}

/// Watch this anywhere in the app to keep the user socket alive.
final userSocketProvider = NotifierProvider<UserSocketNotifier, bool>(
  UserSocketNotifier.new,
);
