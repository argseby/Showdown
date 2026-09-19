import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account.dart';
import 'providers.dart';
import 'rest_client.dart';

/// How one profile stands to another, as the server names it.
class Relation {
  static const none = 'none';
  static const friend = 'friend';
  static const pendingOut = 'pending_out';
  static const pendingIn = 'pending_in';
  static const blocked = 'blocked';
}

/// Another profile: a friend, an ask in either direction, or a search hit.
class Friend {
  const Friend({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.since,
    required this.relation,
  });

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
    id: json['id'] as String? ?? '',
    handle: json['handle'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '',
    since: (json['since'] as num?)?.toInt() ?? 0,
    relation: json['relation'] as String? ?? Relation.none,
  );

  final String id;
  final String handle;
  final String displayName;

  /// Friends since, or when the ask was sent.
  final int since;
  final String relation;
}

/// An invitation to a table, waiting to be taken up.
class TableInvite {
  const TableInvite({
    required this.id,
    required this.tableId,
    required this.tableName,
    required this.from,
    required this.createdAt,
    required this.expiresAt,
  });

  factory TableInvite.fromJson(Map<String, dynamic> json) => TableInvite(
    id: json['id'] as String? ?? '',
    tableId: json['table_id'] as String? ?? '',
    tableName: json['table_name'] as String? ?? '',
    from: json['from'] as String? ?? '',
    createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
    expiresAt: (json['expires_at'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String tableId;
  final String tableName;

  /// The handle of the friend who sent it.
  final String from;
  final int createdAt;
  final int expiresAt;
}

/// Everything the friends screen shows, in one answer.
class FriendsView {
  const FriendsView({
    this.friends = const [],
    this.incoming = const [],
    this.outgoing = const [],
    this.blocked = const [],
    this.invites = const [],
  });

  factory FriendsView.fromJson(Map<String, dynamic> json) {
    List<Friend> list(String key) => [
      for (final f in json[key] as List<dynamic>? ?? const [])
        Friend.fromJson(f as Map<String, dynamic>),
    ];
    return FriendsView(
      friends: list('friends'),
      incoming: list('incoming'),
      outgoing: list('outgoing'),
      blocked: list('blocked'),
      invites: [
        for (final i in json['invites'] as List<dynamic>? ?? const [])
          TableInvite.fromJson(i as Map<String, dynamic>),
      ],
    );
  }

  final List<Friend> friends;
  final List<Friend> incoming;
  final List<Friend> outgoing;
  final List<Friend> blocked;
  final List<TableInvite> invites;

  /// What wants an answer: asks plus invitations.
  int get waiting => incoming.length + invites.length;
}

/// A friend at a table, as the home screen lists them.
class PlayingFriend {
  const PlayingFriend({
    required this.handle,
    required this.displayName,
    required this.name,
    required this.connected,
  });

  factory PlayingFriend.fromJson(Map<String, dynamic> json) => PlayingFriend(
    handle: json['handle'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '',
    name: json['name'] as String? ?? '',
    connected: json['connected'] as bool? ?? false,
  );

  final String handle;
  final String displayName;

  /// The name they are playing under at that table.
  final String name;
  final bool connected;
}

/// A table friends are playing at right now.
class PlayingTable {
  const PlayingTable({
    required this.id,
    required this.name,
    required this.state,
    required this.smallBlind,
    required this.bigBlind,
    required this.seated,
    required this.maxPlayers,
    required this.freeSeats,
    required this.requiresPassword,
    required this.joinPolicy,
    required this.allowSpectators,
    required this.tournament,
    required this.friends,
  });

  factory PlayingTable.fromJson(Map<String, dynamic> json) {
    final blinds = json['blinds'] as Map<String, dynamic>? ?? const {};
    return PlayingTable(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      state: json['state'] as String? ?? '',
      smallBlind: (blinds['small_blind'] as num?)?.toInt() ?? 0,
      bigBlind: (blinds['big_blind'] as num?)?.toInt() ?? 0,
      seated: json['seated'] as int? ?? 0,
      maxPlayers: json['max_players'] as int? ?? 0,
      freeSeats: json['free_seats'] as int? ?? 0,
      requiresPassword: json['requires_password'] as bool? ?? false,
      joinPolicy: json['join_policy'] as String? ?? 'always',
      allowSpectators: json['allow_spectators'] as bool? ?? true,
      tournament: json['tournament'] as bool? ?? false,
      friends: [
        for (final f in json['friends'] as List<dynamic>? ?? const [])
          PlayingFriend.fromJson(f as Map<String, dynamic>),
      ],
    );
  }

  final String id;
  final String name;
  final String state;
  final int smallBlind;
  final int bigBlind;
  final int seated;
  final int maxPlayers;
  final int freeSeats;
  final bool requiresPassword;
  final String joinPolicy;
  final bool allowSpectators;
  final bool tournament;
  final List<PlayingFriend> friends;

  /// Whether somebody could take a seat right now.
  bool get hasRoom => freeSeats > 0 && joinPolicy != 'closed';
}

/// Another player's profile, with only the sections they share.
class PublicProfile {
  const PublicProfile({
    required this.handle,
    required this.displayName,
    required this.since,
    required this.you,
    required this.relation,
    this.winnings,
    this.bestHands,
    this.achievements,
    this.lastHand,
    this.playingAt,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    final activity = json['activity'] as Map<String, dynamic>?;
    return PublicProfile(
      handle: json['handle'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      since: (json['since'] as num?)?.toInt() ?? 0,
      you: json['you'] as bool? ?? false,
      relation: json['relation'] as String? ?? Relation.none,
      winnings: json['winnings'] == null
          ? null
          : ProfileWinnings.fromJson(json['winnings'] as Map<String, dynamic>),
      bestHands: json['best_hands'] == null
          ? null
          : [
              for (final h in json['best_hands'] as List<dynamic>)
                HandHighlight.fromJson(h as Map<String, dynamic>),
            ],
      achievements: json['achievements'] == null
          ? null
          : [
              for (final a in json['achievements'] as List<dynamic>)
                Achievement.fromJson(a as Map<String, dynamic>),
            ],
      lastHand: (activity?['last_hand'] as num?)?.toInt(),
      playingAt: activity?['playing'] as String?,
    );
  }

  final String handle;
  final String displayName;
  final int since;
  final bool you;
  final String relation;

  /// Null when the section is not shared with this viewer.
  final ProfileWinnings? winnings;
  final List<HandHighlight>? bestHands;
  final List<Achievement>? achievements;
  final int? lastHand;

  /// The table they are sitting at, when activity is shared.
  final String? playingAt;
}

/// The public money figures: the counted ones only.
class ProfileWinnings {
  const ProfileWinnings({
    required this.hands,
    required this.net,
    required this.netBB,
    required this.bbPer100,
    required this.roundsWon,
    required this.podiums,
  });

  factory ProfileWinnings.fromJson(Map<String, dynamic> json) =>
      ProfileWinnings(
        hands: json['hands'] as int? ?? 0,
        net: (json['net'] as num?)?.toInt() ?? 0,
        netBB: (json['net_bb'] as num?)?.toDouble() ?? 0,
        bbPer100: (json['bb_per_100'] as num?)?.toDouble() ?? 0,
        roundsWon: json['rounds_won'] as int? ?? 0,
        podiums: json['podiums'] as int? ?? 0,
      );

  final int hands;
  final int net;
  final double netBB;
  final double bbPer100;
  final int roundsWon;
  final int podiums;
}

/// The friends half of the API.
class FriendsApi {
  FriendsApi(this._rest);

  final RestClient _rest;

  Future<FriendsView> list(String token) async =>
      FriendsView.fromJson(await _rest.getJson('/api/friends', token: token));

  Future<List<Friend>> search(String token, String query) async {
    final json = await _rest.getJson(
      '/api/friends/search?q=${Uri.encodeQueryComponent(query)}',
      token: token,
    );
    return [
      for (final f in json['results'] as List<dynamic>? ?? const [])
        Friend.fromJson(f as Map<String, dynamic>),
    ];
  }

  /// Asks somebody to be friends; the answer says whether that already
  /// made the friendship (they had asked too).
  Future<String> request(String token, String handle) async {
    final json = await _rest.postJson('/api/friends/requests', {
      'handle': handle,
    }, token: token);
    return json['state'] as String? ?? Relation.pendingOut;
  }

  /// Answers an ask: accept, decline or block.
  Future<String> answer(String token, String handle, String action) async {
    final json = await _rest.postJson(
      '/api/friends/requests/$handle/$action',
      const {},
      token: token,
    );
    return json['state'] as String? ?? Relation.none;
  }

  Future<void> unfriend(String token, String handle) =>
      _rest.delete('/api/friends/$handle', token: token);

  Future<void> unblock(String token, String handle) =>
      _rest.delete('/api/friends/blocks/$handle', token: token);

  Future<List<PlayingTable>> playing(String token) async {
    final json = await _rest.getJson('/api/friends/playing', token: token);
    return [
      for (final t in json['tables'] as List<dynamic>? ?? const [])
        PlayingTable.fromJson(t as Map<String, dynamic>),
    ];
  }

  /// Asks a friend to a table the caller is sitting at.
  Future<String> invite(String token, String tableId, String handle) async {
    final json = await _rest.postJson('/api/tables/$tableId/invites', {
      'handle': handle,
    }, token: token);
    return json['invite_id'] as String? ?? '';
  }

  Future<void> dismissInvite(String token, String id) =>
      _rest.delete('/api/friends/invites/$id', token: token);

  /// Another player's profile. Null when there is nothing to see: a
  /// profile kept private is answered with the same 404 as one that does
  /// not exist.
  Future<PublicProfile?> profile(String? token, String handle) async {
    try {
      return PublicProfile.fromJson(
        await _rest.getJson('/api/profiles/$handle', token: token),
      );
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }
}

final friendsApiProvider = Provider<FriendsApi>(
  (ref) => FriendsApi(ref.watch(restClientProvider)),
);

/// The friends screen's data; null while signed out.
final friendsProvider = FutureProvider<FriendsView?>((ref) async {
  final account = await ref.watch(accountProvider.future);
  final token = ref.read(accountProvider.notifier).token;
  if (account == null || token == null) return null;
  return ref.read(friendsApiProvider).list(token);
});

/// The tables friends are at right now; empty while signed out.
final friendsPlayingProvider = FutureProvider<List<PlayingTable>>((ref) async {
  final account = await ref.watch(accountProvider.future);
  final token = ref.read(accountProvider.notifier).token;
  if (account == null || token == null) return const [];
  return ref.read(friendsApiProvider).playing(token);
});

/// One player's profile, as far as they share it.
final profileProvider = FutureProvider.family<PublicProfile?, String>((
  ref,
  handle,
) async {
  await ref.watch(accountProvider.future);
  final token = ref.read(accountProvider.notifier).token;
  return ref.read(friendsApiProvider).profile(token, handle);
});
