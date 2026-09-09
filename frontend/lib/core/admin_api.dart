import 'rest_client.dart';

class AdminSettings {
  const AdminSettings({
    required this.requiresPassword,
    required this.maxPlayers,
    required this.startMoney,
    required this.smallBlind,
    required this.bigBlind,
    required this.ante,
    required this.turnTime,
    required this.disconnectedTurnTime,
    required this.sitOutAfterMissedTurns,
    required this.joinPolicy,
    required this.allowSpectators,
    required this.spectatorChat,
    required this.chatEnabled,
    required this.allowRebuy,
    required this.showdownReveal,
    required this.autoStart,
    required this.handDelayMs,
    this.allowRabbitHunt = true,
    this.blindsUpMinutes = 0,
    this.blindsUpPercent = 100,
    this.timeBankSeconds = 30,
    this.timeBankRefillSeconds = 1,
    this.allowStraddle = false,
    this.runItTwice = false,
    this.variant = 'holdem',
  });

  factory AdminSettings.fromJson(Map<String, dynamic> json) => AdminSettings(
    requiresPassword: json['requires_password'] as bool,
    maxPlayers: json['max_players'] as int,
    startMoney: json['start_money'] as int,
    smallBlind: json['small_blind'] as int,
    bigBlind: json['big_blind'] as int,
    ante: json['ante'] as int,
    turnTime: json['turn_time'] as int,
    disconnectedTurnTime: json['disconnected_turn_time'] as int,
    sitOutAfterMissedTurns: json['sit_out_after_missed_turns'] as int,
    joinPolicy: json['join_policy'] as String,
    allowSpectators: json['allow_spectators'] as bool,
    spectatorChat: json['spectator_chat'] as bool,
    chatEnabled: json['chat_enabled'] as bool,
    allowRebuy: json['allow_rebuy'] as bool,
    showdownReveal: json['showdown_reveal'] as String,
    autoStart: json['auto_start'] as bool,
    handDelayMs: json['hand_delay_ms'] as int,
    allowRabbitHunt: json['allow_rabbit_hunt'] as bool? ?? true,
    blindsUpMinutes: json['blinds_up_minutes'] as int? ?? 0,
    blindsUpPercent: json['blinds_up_percent'] as int? ?? 100,
    timeBankSeconds: json['time_bank_seconds'] as int? ?? 30,
    timeBankRefillSeconds: json['time_bank_refill_seconds'] as int? ?? 1,
    allowStraddle: json['allow_straddle'] as bool? ?? false,
    runItTwice: json['run_it_twice'] as bool? ?? false,
    variant: json['variant'] as String? ?? 'holdem',
  );

  /// The §5.2 defaults, used by the new-table form.
  static const defaults = AdminSettings(
    requiresPassword: false,
    maxPlayers: 9,
    startMoney: 10000,
    smallBlind: 50,
    bigBlind: 100,
    ante: 0,
    turnTime: 30,
    disconnectedTurnTime: 10,
    sitOutAfterMissedTurns: 2,
    joinPolicy: 'always',
    allowSpectators: true,
    spectatorChat: true,
    chatEnabled: true,
    allowRebuy: true,
    showdownReveal: 'all',
    autoStart: true,
    handDelayMs: 5000,
  );

  final bool requiresPassword;
  final int maxPlayers;
  final int startMoney;
  final int smallBlind;
  final int bigBlind;
  final int ante;
  final int turnTime;
  final int disconnectedTurnTime;
  final int sitOutAfterMissedTurns;
  final String joinPolicy;
  final bool allowSpectators;
  final bool spectatorChat;
  final bool chatEnabled;
  final bool allowRebuy;
  final String showdownReveal;
  final bool autoStart;
  final int handDelayMs;
  final bool allowRabbitHunt;
  final int blindsUpMinutes;
  final int blindsUpPercent;
  final int timeBankSeconds;
  final int timeBankRefillSeconds;
  final bool allowStraddle;
  final bool runItTwice;

  /// The deck: 'holdem' (52 cards) or 'royal' (Ten to Ace only).
  final String variant;

  /// Field values keyed by wire name (password excluded).
  Map<String, Object> toFields() => {
    'max_players': maxPlayers,
    'start_money': startMoney,
    'small_blind': smallBlind,
    'big_blind': bigBlind,
    'ante': ante,
    'turn_time': turnTime,
    'disconnected_turn_time': disconnectedTurnTime,
    'sit_out_after_missed_turns': sitOutAfterMissedTurns,
    'join_policy': joinPolicy,
    'allow_spectators': allowSpectators,
    'spectator_chat': spectatorChat,
    'chat_enabled': chatEnabled,
    'allow_rebuy': allowRebuy,
    'showdown_reveal': showdownReveal,
    'auto_start': autoStart,
    'hand_delay_ms': handDelayMs,
    'allow_rabbit_hunt': allowRabbitHunt,
    'blinds_up_minutes': blindsUpMinutes,
    'blinds_up_percent': blindsUpPercent,
    'time_bank_seconds': timeBankSeconds,
    'time_bank_refill_seconds': timeBankRefillSeconds,
    'allow_straddle': allowStraddle,
    'run_it_twice': runItTwice,
    'variant': variant,
  };
}

/// Player row of the admin detail view.
class AdminPlayer {
  const AdminPlayer({
    required this.id,
    required this.name,
    required this.seat,
    required this.stack,
    required this.status,
    required this.connected,
    required this.muted,
    required this.missedTurns,
    required this.buyInTotal,
    required this.handsPlayed,
    required this.handsWon,
    required this.biggestPot,
    required this.joinedAt,
    this.voice = 'off',
    this.camera = false,
  });

  factory AdminPlayer.fromJson(Map<String, dynamic> json) => AdminPlayer(
    id: json['id'] as String,
    name: json['name'] as String,
    seat: json['seat'] as int,
    stack: json['stack'] as int,
    status: json['status'] as String,
    connected: json['connected'] as bool,
    muted: json['muted'] as bool,
    missedTurns: json['missed_turns'] as int,
    buyInTotal: json['buy_in_total'] as int,
    handsPlayed: json['hands_played'] as int,
    handsWon: json['hands_won'] as int,
    biggestPot: json['biggest_pot'] as int,
    joinedAt: json['joined_at'] as int,
    voice: json['voice'] as String? ?? 'off',
    camera: json['camera'] as bool? ?? false,
  );

  final String id;
  final String name;
  final int seat;
  final int stack;
  final String status;
  final bool connected;
  final bool muted;

  /// Voice-chat presence: off, on or muted.
  final String voice;

  /// The player's camera is on.
  final bool camera;
  final int missedTurns;
  final int buyInTotal;
  final int handsPlayed;
  final int handsWon;
  final int biggestPot;
  final int joinedAt;
}

/// `GET /api/admin/tables/{id}`.
class AdminTableDetail {
  const AdminTableDetail({
    required this.id,
    required this.name,
    required this.state,
    required this.handNumber,
    required this.createdAt,
    required this.endedAt,
    required this.settings,
    required this.players,
    required this.spectators,
    required this.connections,
    required this.joinUrl,
  });

  factory AdminTableDetail.fromJson(Map<String, dynamic> json) =>
      AdminTableDetail(
        id: json['id'] as String,
        name: json['name'] as String,
        state: json['state'] as String,
        handNumber: json['hand_number'] as int,
        createdAt: json['created_at'] as int,
        endedAt: json['ended_at'] as int?,
        settings: AdminSettings.fromJson(
          json['settings'] as Map<String, dynamic>,
        ),
        players: [
          for (final p in json['players'] as List<dynamic>)
            AdminPlayer.fromJson(p as Map<String, dynamic>),
        ],
        spectators: json['spectators'] as int,
        connections: json['connections'] as int,
        joinUrl: json['join_url'] as String,
      );

  final String id;
  final String name;
  final String state;
  final int handNumber;
  final int createdAt;
  final int? endedAt;
  final AdminSettings settings;
  final List<AdminPlayer> players;
  final int spectators;
  final int connections;
  final String joinUrl;
}

/// Result of a settings PATCH.
class SettingsUpdateResult {
  const SettingsUpdateResult({
    required this.changed,
    required this.appliesNextHand,
    required this.settings,
  });
  final List<String> changed;
  final List<String> appliesNextHand;
  final AdminSettings settings;
}

/// One stored hand (`GET /api/admin/tables/{id}/hands`).
class HandRecord {
  const HandRecord({
    required this.id,
    required this.number,
    required this.startedAt,
    required this.endedAt,
    required this.buttonSeat,
    required this.smallBlind,
    required this.bigBlind,
    required this.ante,
    required this.stacksAtStart,
    required this.events,
    required this.voided,
  });

  factory HandRecord.fromJson(Map<String, dynamic> json) => HandRecord(
    id: json['id'] as int,
    number: json['number'] as int,
    startedAt: json['started_at'] as int,
    endedAt: json['ended_at'] as int?,
    buttonSeat: json['button_seat'] as int,
    smallBlind: json['small_blind'] as int,
    bigBlind: json['big_blind'] as int,
    ante: json['ante'] as int,
    stacksAtStart: {
      for (final e
          in (json['stacks_at_start'] as Map<String, dynamic>? ?? const {})
              .entries)
        int.parse(e.key): e.value as int,
    },
    events: [
      for (final e in json['events'] as List<dynamic>? ?? const [])
        e as Map<String, dynamic>,
    ],
    voided: json['voided'] as bool,
  );

  final int id;
  final int number;
  final int startedAt;
  final int? endedAt;
  final int buttonSeat;
  final int smallBlind;
  final int bigBlind;
  final int ante;
  final Map<int, int> stacksAtStart;
  final List<Map<String, dynamic>> events;
  final bool voided;
}

/// Result of creating a table.
class CreatedTable {
  const CreatedTable({required this.detail, required this.adminToken});
  final AdminTableDetail detail;
  final String adminToken;
}

class AdminApi {
  AdminApi(this._rest);

  final RestClient _rest;

  /// Creates a table (public). The caller becomes its admin and receives the
  /// admin token exactly once, in this response.
  Future<CreatedTable> createTable({
    required String name,
    required Map<String, Object?> settings,
  }) async {
    final json = await _rest.postJson('/api/tables', {
      'name': name,
      'settings': settings,
    });
    return CreatedTable(
      detail: AdminTableDetail.fromJson(json),
      adminToken: json['admin_token'] as String,
    );
  }

  Future<AdminTableDetail> getTable(String token, String id) async =>
      AdminTableDetail.fromJson(
        await _rest.getJson('/api/admin/tables/$id', token: token),
      );

  Future<SettingsUpdateResult> patchSettings(
    String token,
    String id,
    Map<String, Object?> patch,
  ) async {
    final json = await _rest.patchJson(
      '/api/admin/tables/$id/settings',
      patch,
      token: token,
    );
    return SettingsUpdateResult(
      changed: [for (final f in json['changed'] as List<dynamic>) f as String],
      appliesNextHand: [
        for (final f in json['applies_next_hand'] as List<dynamic>) f as String,
      ],
      settings: AdminSettings.fromJson(
        json['settings'] as Map<String, dynamic>,
      ),
    );
  }

  Future<String> lifecycle(
    String token,
    String id,
    String op, {
    bool immediate = false,
  }) async {
    final json = await _rest.postJson(
      '/api/admin/tables/$id/$op',
      op == 'end' ? {'immediate': immediate} : null,
      token: token,
    );
    return json['state'] as String;
  }

  /// Raises the blinds now by the configured percentage (blind schedule).
  Future<AdminSettings> blindsUp(String token, String id) async {
    final json = await _rest.postJson(
      '/api/admin/tables/$id/blinds-up',
      null,
      token: token,
    );
    return AdminSettings.fromJson(json['settings'] as Map<String, dynamic>);
  }

  Future<void> deleteTable(String token, String id) =>
      _rest.delete('/api/admin/tables/$id', token: token);

  Future<void> kick(String token, String id, String playerId) => _rest.postJson(
    '/api/admin/tables/$id/players/$playerId/kick',
    null,
    token: token,
  );

  /// Returns true when applied immediately, false when queued for the hand end.
  Future<bool> adjustChips(
    String token,
    String id,
    String playerId, {
    required int delta,
    required String note,
  }) async {
    final json = await _rest.postJson(
      '/api/admin/tables/$id/players/$playerId/chips',
      {'delta': delta, 'note': note},
      token: token,
    );
    return json['applied'] as bool;
  }

  Future<void> mute(
    String token,
    String id,
    String playerId, {
    required bool muted,
  }) => _rest.postJson('/api/admin/tables/$id/players/$playerId/mute', {
    'muted': muted,
  }, token: token);

  /// Mutes a player's microphone; only the player can unmute it again.
  Future<void> muteVoice(String token, String id, String playerId) =>
      _rest.postJson(
        '/api/admin/tables/$id/players/$playerId/voice-mute',
        null,
        token: token,
      );

  /// Turns a player's camera off; only the player can turn it on again.
  Future<void> cameraOff(String token, String id, String playerId) =>
      _rest.postJson(
        '/api/admin/tables/$id/players/$playerId/camera-off',
        null,
        token: token,
      );

  /// Hand history for a player or spectator of the table (their session
  /// token); hole cards only for their own seat and revealed hands.
  Future<List<HandRecord>> sessionHands(
    String token,
    String id, {
    int limit = 20,
    int before = 0,
  }) async {
    final json = await _rest.getJson(
      '/api/tables/$id/hands?limit=$limit&before=$before',
      token: token,
    );
    return [
      for (final h in json['hands'] as List<dynamic>)
        HandRecord.fromJson(h as Map<String, dynamic>),
    ];
  }

  Future<List<HandRecord>> hands(
    String token,
    String id, {
    int limit = 20,
    int before = 0,
  }) async {
    final json = await _rest.getJson(
      '/api/admin/tables/$id/hands?limit=$limit&before=$before',
      token: token,
    );
    return [
      for (final h in json['hands'] as List<dynamic>)
        HandRecord.fromJson(h as Map<String, dynamic>),
    ];
  }

  Future<void> deleteChat(String token, String tableId, int messageId) =>
      _rest.delete('/api/admin/chat/$tableId/$messageId', token: token);
}
