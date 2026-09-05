import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A stored table session: the token plus what it stands for.
class StoredSession {
  const StoredSession({
    required this.token,
    required this.role,
    required this.name,
    this.playerId,
    this.voice = false,
    this.voiceMuted = false,
  });

  factory StoredSession.fromJson(Map<String, dynamic> json) => StoredSession(
    token: json['token'] as String,
    role: json['role'] as String,
    name: json['name'] as String? ?? '',
    playerId: json['player_id'] as String?,
    voice: json['voice'] as bool? ?? false,
    voiceMuted: json['voice_muted'] as bool? ?? false,
  );

  final String token;
  final String role; // player | spectator
  final String name;
  final String? playerId;

  /// The player is in the voice chat (chosen at join or at the table).
  final bool voice;

  /// The microphone was muted when the page was last open.
  final bool voiceMuted;

  StoredSession copyWith({bool? voice, bool? voiceMuted}) => StoredSession(
    token: token,
    role: role,
    name: name,
    playerId: playerId,
    voice: voice ?? this.voice,
    voiceMuted: voiceMuted ?? this.voiceMuted,
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'role': role,
    'name': name,
    if (playerId != null) 'player_id': playerId,
    if (voice) 'voice': true,
    if (voiceMuted) 'voice_muted': true,
  };
}

/// Persists `{tableId -> session}` in shared_preferences.
class SessionStore {
  SessionStore([Future<SharedPreferences>? prefs])
    : _prefs = prefs ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _prefs;

  static String _key(String tableId) => 'session:$tableId';

  Future<StoredSession?> load(String tableId) async {
    final p = await _prefs;
    final raw = p.getString(_key(tableId));
    if (raw == null) return null;
    try {
      return StoredSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  Future<void> save(String tableId, StoredSession session) async {
    final p = await _prefs;
    await p.setString(_key(tableId), jsonEncode(session.toJson()));
  }

  Future<void> clear(String tableId) async {
    final p = await _prefs;
    await p.remove(_key(tableId));
  }

  static String _adminKey(String tableId) => 'admin:$tableId';

  /// The admin token of a table this device created (or entered the key
  /// for); null when this device does not host the table.
  Future<String?> loadAdminToken(String tableId) async {
    final p = await _prefs;
    final raw = p.getString(_adminKey(tableId));
    return raw == null || raw.isEmpty ? null : raw;
  }

  Future<void> saveAdminToken(String tableId, String token) async {
    final p = await _prefs;
    await p.setString(_adminKey(tableId), token);
  }

  Future<void> clearAdminToken(String tableId) async {
    final p = await _prefs;
    await p.remove(_adminKey(tableId));
  }
}

final sessionStoreProvider = Provider<SessionStore>((ref) => SessionStore());

/// The stored session for one table (null when none).
class SessionNotifier extends AsyncNotifier<StoredSession?> {
  SessionNotifier(this.tableId);

  final String tableId;

  @override
  Future<StoredSession?> build() =>
      ref.read(sessionStoreProvider).load(tableId);

  Future<void> save(StoredSession session) async {
    await ref.read(sessionStoreProvider).save(tableId, session);
    state = AsyncData(session);
  }

  Future<void> clear() async {
    await ref.read(sessionStoreProvider).clear(tableId);
    state = const AsyncData(null);
  }
}

final sessionProvider =
    AsyncNotifierProvider.family<SessionNotifier, StoredSession?, String>(
      SessionNotifier.new,
    );

/// The stored admin token for one table (null when this device is not the
/// host).
class AdminTokenNotifier extends AsyncNotifier<String?> {
  AdminTokenNotifier(this.tableId);

  final String tableId;

  @override
  Future<String?> build() =>
      ref.read(sessionStoreProvider).loadAdminToken(tableId);

  Future<void> save(String token) async {
    await ref.read(sessionStoreProvider).saveAdminToken(tableId, token);
    state = AsyncData(token);
  }

  Future<void> clear() async {
    await ref.read(sessionStoreProvider).clearAdminToken(tableId);
    state = const AsyncData(null);
  }
}

final adminTokenProvider =
    AsyncNotifierProvider.family<AdminTokenNotifier, String?, String>(
      AdminTokenNotifier.new,
    );
