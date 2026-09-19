import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers.dart';
import 'rest_client.dart';

/// A player profile as its owner sees it. Profiles are optional: a guest has
/// none and can do everything except keep statistics.
class Account {
  const Account({
    required this.id,
    required this.handle,
    required this.displayName,
    this.visibility = const {},
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as String,
    handle: json['handle'] as String,
    displayName: json['display_name'] as String? ?? json['handle'] as String,
    visibility: {
      for (final e
          in (json['visibility'] as Map<String, dynamic>? ?? const {}).entries)
        e.key: e.value as String,
    },
  );

  final String id;
  final String handle;
  final String displayName;

  /// Who may see each part: "private", "friends" or "public". Nothing reads
  /// this yet; the profile page will.
  final Map<String, String> visibility;
}

/// How often one kind of hand was made, and how much of that the table got
/// to see. [category] is the server's poker category (0 high card .. 8
/// straight flush); [royal] marks the ace-high straight flush.
/// One hand worth keeping: what it was, what it paid and where.
class HandHighlight {
  const HandHighlight({
    required this.category,
    required this.royal,
    required this.description,
    required this.cards,
    required this.net,
    required this.won,
    required this.wonBB,
    required this.bigBlind,
    required this.tableName,
    required this.handNumber,
    required this.endedAt,
    required this.shown,
    required this.counted,
  });

  factory HandHighlight.fromJson(Map<String, dynamic> json) => HandHighlight(
    category: json['category'] as int? ?? -1,
    royal: json['royal'] as bool? ?? false,
    description: json['description'] as String? ?? '',
    cards: [
      for (final c in json['cards'] as List<dynamic>? ?? const []) c as String,
    ],
    net: (json['net'] as num?)?.toInt() ?? 0,
    won: (json['won'] as num?)?.toInt() ?? 0,
    wonBB: (json['won_bb'] as num?)?.toDouble() ?? 0,
    bigBlind: (json['big_blind'] as num?)?.toInt() ?? 0,
    tableName: json['table_name'] as String? ?? '',
    handNumber: json['hand_number'] as int? ?? 0,
    endedAt: (json['ended_at'] as num?)?.toInt() ?? 0,
    shown: json['shown'] as bool? ?? false,
    counted: json['counted'] as bool? ?? false,
  );

  final int category;
  final bool royal;
  final String description;

  /// The five cards that made the hand.
  final List<String> cards;
  final int net;
  final int won;
  final double wonBB;
  final int bigBlind;
  final String tableName;
  final int handNumber;
  final int endedAt;

  /// Whether the table saw it; a mucked hand is only ever on your own page.
  final bool shown;
  final bool counted;
}

/// A milestone. [earnedAt] is 0 while it is still ahead, and the counted
/// ones carry how far along the profile is.
class Achievement {
  const Achievement({
    required this.id,
    required this.earnedAt,
    required this.progress,
    required this.goal,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'] as String,
    earnedAt: (json['earned_at'] as num?)?.toInt() ?? 0,
    progress: json['progress'] as int? ?? 0,
    goal: json['goal'] as int? ?? 0,
  );

  final String id;
  final int earnedAt;
  final int progress;
  final int goal;

  bool get earned => earnedAt > 0;
}

/// The hands and milestones behind the totals.
class ProfileHighlights {
  const ProfileHighlights({
    this.bestHands = const [],
    this.biggestWins = const [],
    this.achievements = const [],
  });

  factory ProfileHighlights.fromJson(Map<String, dynamic> json) {
    List<HandHighlight> hands(String key) => [
      for (final h in json[key] as List<dynamic>? ?? const [])
        HandHighlight.fromJson(h as Map<String, dynamic>),
    ];
    return ProfileHighlights(
      bestHands: hands('best_hands'),
      biggestWins: hands('biggest_wins'),
      achievements: [
        for (final a in json['achievements'] as List<dynamic>? ?? const [])
          Achievement.fromJson(a as Map<String, dynamic>),
      ],
    );
  }

  final List<HandHighlight> bestHands;
  final List<HandHighlight> biggestWins;
  final List<Achievement> achievements;

  List<Achievement> get earned => [
    for (final a in achievements)
      if (a.earned) a,
  ];
  List<Achievement> get ahead => [
    for (final a in achievements)
      if (!a.earned) a,
  ];
}

class HandClassCount {
  const HandClassCount({
    required this.category,
    required this.royal,
    required this.made,
    required this.shown,
  });

  factory HandClassCount.fromJson(Map<String, dynamic> json) => HandClassCount(
    category: json['category'] as int,
    royal: json['royal'] as bool? ?? false,
    made: json['made'] as int? ?? 0,
    shown: json['shown'] as int? ?? 0,
  );

  final int category;
  final bool royal;

  /// Hands taken to the end, shown or mucked.
  final int made;

  /// Of those, the ones the table saw.
  final int shown;
}

/// A profile's own record. Everything here is private to its owner.
class ProfileStats {
  const ProfileStats({
    this.hands = 0,
    this.tables = 0,
    this.rounds = 0,
    this.firstHand = 0,
    this.lastHand = 0,
    this.net = 0,
    this.netBB = 0,
    this.bbPer100 = 0,
    this.countedHands = 0,
    this.countedNet = 0,
    this.countedNetBB = 0,
    this.biggestPot = 0,
    this.biggestWin = 0,
    this.bestRound = 0,
    this.handsWon = 0,
    this.roundsWon = 0,
    this.podiums = 0,
    this.tournaments = 0,
    this.vpip = 0,
    this.showdowns = 0,
    this.showdownsWon = 0,
    this.wonWithoutShowdown = 0,
    this.folded = 0,
    this.allIns = 0,
    this.handClasses = const [],
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    int i(String key) => (json[key] as num?)?.toInt() ?? 0;
    double d(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return ProfileStats(
      hands: i('hands'),
      tables: i('tables'),
      rounds: i('rounds'),
      firstHand: i('first_hand'),
      lastHand: i('last_hand'),
      net: i('net'),
      netBB: d('net_bb'),
      bbPer100: d('bb_per_100'),
      countedHands: i('counted_hands'),
      countedNet: i('counted_net'),
      countedNetBB: d('counted_net_bb'),
      biggestPot: i('biggest_pot'),
      biggestWin: i('biggest_win'),
      bestRound: i('best_round'),
      handsWon: i('hands_won'),
      roundsWon: i('rounds_won'),
      podiums: i('podiums'),
      tournaments: i('tournaments'),
      vpip: i('vpip'),
      showdowns: i('showdowns'),
      showdownsWon: i('showdowns_won'),
      wonWithoutShowdown: i('won_without_showdown'),
      folded: i('folded'),
      allIns: i('all_ins'),
      handClasses: [
        for (final c in json['hand_classes'] as List<dynamic>? ?? const [])
          HandClassCount.fromJson(c as Map<String, dynamic>),
      ],
    );
  }

  final int hands;
  final int tables;
  final int rounds;
  final int firstHand;
  final int lastHand;

  /// Chips, and the same in big blinds — the only figure that compares
  /// across tables of different stakes.
  final int net;
  final double netBB;
  final double bbPer100;

  /// The subset that may ever stand in a public total: three or more
  /// profiles dealt in, nobody handed chips.
  final int countedHands;
  final int countedNet;
  final double countedNetBB;

  final int biggestPot;
  final int biggestWin;
  final int bestRound;
  final int handsWon;
  final int roundsWon;
  final int podiums;
  final int tournaments;

  final int vpip;
  final int showdowns;
  final int showdownsWon;
  final int wonWithoutShowdown;
  final int folded;
  final int allIns;

  final List<HandClassCount> handClasses;

  bool get empty => hands == 0;

  /// Percentages, guarded against an empty record.
  double get vpipPercent => hands == 0 ? 0 : vpip * 100 / hands;
  double get foldPercent => hands == 0 ? 0 : folded * 100 / hands;
  double get showdownWinPercent =>
      showdowns == 0 ? 0 : showdownsWon * 100 / showdowns;
}

/// The REST calls of the profile API.
class AccountApi {
  AccountApi(this._rest);
  final RestClient _rest;

  /// Creates a profile and signs this device in. The recovery code comes
  /// back once and is never retrievable again.
  Future<({String token, Account account, String recoveryCode})> register({
    required String handle,
    required String password,
    String? displayName,
  }) async {
    final json = await _rest.postJson('/api/accounts', {
      'handle': handle,
      'password': password,
      'display_name': ?displayName,
    });
    return (
      token: json['token'] as String,
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
      recoveryCode: json['recovery_code'] as String,
    );
  }

  Future<({String token, Account account})> signIn({
    required String handle,
    required String password,
  }) async {
    final json = await _rest.postJson('/api/accounts/session', {
      'handle': handle,
      'password': password,
    });
    return (
      token: json['token'] as String,
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
    );
  }

  Future<void> signOut(String token) =>
      _rest.delete('/api/accounts/session', token: token);

  /// Sets a new password. Every other device is signed out and a fresh
  /// recovery code comes back — the old one is spent.
  Future<({String token, String recoveryCode})> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final json = await _rest.postJson('/api/accounts/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    }, token: token);
    return (
      token: json['token'] as String,
      recoveryCode: json['recovery_code'] as String,
    );
  }

  /// The signed-in profile's own record.
  Future<ProfileStats> stats(String token) async => ProfileStats.fromJson(
    await _rest.getJson('/api/accounts/me/stats', token: token),
  );

  /// The hands and milestones behind the record.
  Future<ProfileHighlights> highlights(String token) async =>
      ProfileHighlights.fromJson(
        await _rest.getJson('/api/accounts/me/highlights', token: token),
      );

  /// Changes the display name, the visibility of a section, or both.
  Future<Account> updateProfile({
    required String token,
    String? displayName,
    Map<String, String>? visibility,
  }) async {
    final json = await _rest.patchJson('/api/accounts/me', {
      'display_name': ?displayName,
      'visibility': ?visibility,
    }, token: token);
    return Account.fromJson(json['account'] as Map<String, dynamic>);
  }

  Future<Account> me(String token) async {
    final json = await _rest.getJson('/api/accounts/me', token: token);
    return Account.fromJson(json['account'] as Map<String, dynamic>);
  }
}

final accountApiProvider = Provider<AccountApi>(
  (ref) => AccountApi(ref.watch(restClientProvider)),
);

/// The profile token of this device, in the same place the table sessions
/// live. Null while signed out, which is the normal state.
class AccountTokenStore {
  AccountTokenStore([Future<SharedPreferences>? prefs]) : _given = prefs;

  final Future<SharedPreferences>? _given;
  late final Future<SharedPreferences> _prefs =
      _given ?? SharedPreferences.getInstance();
  static const _key = 'account:token';

  Future<String?> load() async {
    final raw = (await _prefs).getString(_key);
    return raw == null || raw.isEmpty ? null : raw;
  }

  Future<void> save(String token) async =>
      (await _prefs).setString(_key, token);
  Future<void> clear() async => (await _prefs).remove(_key);
}

final accountTokenStoreProvider = Provider<AccountTokenStore>(
  (ref) => AccountTokenStore(),
);

/// The signed-in profile, or null for a guest. Loading it is a no-op on an
/// instance without profiles.
class AccountNotifier extends AsyncNotifier<Account?> {
  String? _token;

  /// The bearer token for API calls made on behalf of the profile.
  String? get token => _token;

  @override
  Future<Account?> build() async {
    final store = ref.read(accountTokenStoreProvider);
    final token = await store.load();
    if (token == null) return null;
    try {
      final account = await ref.read(accountApiProvider).me(token);
      _token = token;
      return account;
    } on ApiException {
      // Expired or from an instance that no longer offers profiles.
      await store.clear();
      return null;
    }
  }

  Future<void> _adopt(String token, Account account) async {
    await ref.read(accountTokenStoreProvider).save(token);
    _token = token;
    state = AsyncData(account);
  }

  /// Creates a profile; returns the recovery code to show once.
  Future<String> register({
    required String handle,
    required String password,
    String? displayName,
  }) async {
    final res = await ref
        .read(accountApiProvider)
        .register(handle: handle, password: password, displayName: displayName);
    await _adopt(res.token, res.account);
    return res.recoveryCode;
  }

  Future<void> signIn({
    required String handle,
    required String password,
  }) async {
    final res = await ref
        .read(accountApiProvider)
        .signIn(handle: handle, password: password);
    await _adopt(res.token, res.account);
  }

  /// Sets a new password and keeps this device signed in; returns the new
  /// recovery code to show once.
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = _token;
    if (token == null) throw StateError('not signed in');
    final res = await ref
        .read(accountApiProvider)
        .changePassword(
          token: token,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
    await ref.read(accountTokenStoreProvider).save(res.token);
    _token = res.token;
    return res.recoveryCode;
  }

  /// Shows or hides one section of the profile. The switch belongs to the
  /// owner, so the new state comes back from the server, not from here.
  Future<void> setVisibility(String section, String value) async {
    final token = _token;
    if (token == null) throw StateError('not signed in');
    final account = await ref
        .read(accountApiProvider)
        .updateProfile(token: token, visibility: {section: value});
    state = AsyncData(account);
  }

  Future<void> signOut() async {
    final token = _token;
    _token = null;
    await ref.read(accountTokenStoreProvider).clear();
    state = const AsyncData(null);
    if (token != null) {
      try {
        await ref.read(accountApiProvider).signOut(token);
      } on ApiException {
        // The device is signed out either way.
      }
    }
  }
}

final accountProvider = AsyncNotifierProvider<AccountNotifier, Account?>(
  AccountNotifier.new,
);

/// The signed-in profile's record; null while signed out.
final accountStatsProvider = FutureProvider<ProfileStats?>((ref) async {
  final account = await ref.watch(accountProvider.future);
  final token = ref.read(accountProvider.notifier).token;
  if (account == null || token == null) return null;
  return ref.read(accountApiProvider).stats(token);
});

/// The hands and milestones behind the record; null while signed out.
final accountHighlightsProvider = FutureProvider<ProfileHighlights?>((
  ref,
) async {
  final account = await ref.watch(accountProvider.future);
  final token = ref.read(accountProvider.notifier).token;
  if (account == null || token == null) return null;
  return ref.read(accountApiProvider).highlights(token);
});
