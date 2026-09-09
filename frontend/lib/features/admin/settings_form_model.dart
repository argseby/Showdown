import '../../core/admin_api.dart';

/// Which server-side rule applies to a settings field (docs §5.2 "Applies").
enum AppliesWhen { immediately, nextHand, nextJoin, futureJoins }

const Map<String, AppliesWhen> settingsApplies = {
  'password': AppliesWhen.nextJoin,
  'max_players': AppliesWhen.immediately,
  'start_money': AppliesWhen.futureJoins,
  'small_blind': AppliesWhen.nextHand,
  'big_blind': AppliesWhen.nextHand,
  'ante': AppliesWhen.nextHand,
  'turn_time': AppliesWhen.nextHand,
  'disconnected_turn_time': AppliesWhen.nextHand,
  'sit_out_after_missed_turns': AppliesWhen.immediately,
  'join_policy': AppliesWhen.immediately,
  'allow_spectators': AppliesWhen.immediately,
  'spectator_chat': AppliesWhen.immediately,
  'chat_enabled': AppliesWhen.immediately,
  'allow_rebuy': AppliesWhen.immediately,
  'showdown_reveal': AppliesWhen.nextHand,
  'auto_start': AppliesWhen.immediately,
  'hand_delay_ms': AppliesWhen.nextHand,
  'allow_rabbit_hunt': AppliesWhen.immediately,
  'blinds_up_minutes': AppliesWhen.immediately,
  'blinds_up_percent': AppliesWhen.immediately,
  'time_bank_seconds': AppliesWhen.immediately,
  'time_bank_refill_seconds': AppliesWhen.immediately,
  'allow_straddle': AppliesWhen.nextHand,
  'run_it_twice': AppliesWhen.nextHand,
  'variant': AppliesWhen.nextHand,
};

/// Client-side validation problems, keyed by field.
enum SettingsError {
  integer,
  maxPlayers,
  maxPlayersRoyal,
  startMoney,
  smallBlind,
  bigBlind,
  ante,
  turnTime,
  disconnected,
  sitOut,
  handDelay,
  blindsUpMinutes,
  blindsUpPercent,
  timeBank,
  timeBankRefill,
  password,
  name,
}

/// Pure form state for the settings form: text for numeric fields (so that
/// partial input is representable), enums and booleans, plus validation and
/// the patch of changed fields. The server remains authoritative.
class SettingsFormState {
  const SettingsFormState({
    required this.name,
    required this.password,
    required this.clearPassword,
    required this.numbers,
    required this.joinPolicy,
    required this.showdownReveal,
    required this.variant,
    required this.flags,
    required this.original,
  });

  factory SettingsFormState.fromSettings(AdminSettings s, {String name = ''}) =>
      SettingsFormState(
        name: name,
        password: '',
        clearPassword: false,
        numbers: {
          for (final e in s.toFields().entries)
            if (e.value is int) e.key: '${e.value}',
        },
        joinPolicy: s.joinPolicy,
        showdownReveal: s.showdownReveal,
        variant: s.variant,
        flags: {
          for (final e in s.toFields().entries)
            if (e.value is bool) e.key: e.value as bool,
        },
        original: s,
      );

  final String name;
  final String password;
  final bool clearPassword;
  final Map<String, String> numbers;
  final String joinPolicy;
  final String showdownReveal;

  /// The deck: 'holdem' or 'royal' (Ten to Ace, at most [royalMaxPlayers]).
  final String variant;
  final Map<String, bool> flags;
  final AdminSettings original;

  static const royalMaxPlayers = 6;

  bool get isRoyal => variant == 'royal';

  static const numericFields = [
    'max_players',
    'start_money',
    'small_blind',
    'big_blind',
    'ante',
    'turn_time',
    'disconnected_turn_time',
    'sit_out_after_missed_turns',
    'hand_delay_ms',
    'blinds_up_minutes',
    'blinds_up_percent',
    'time_bank_seconds',
    'time_bank_refill_seconds',
  ];

  SettingsFormState copyWith({
    String? name,
    String? password,
    bool? clearPassword,
    Map<String, String>? numbers,
    String? joinPolicy,
    String? showdownReveal,
    String? variant,
    Map<String, bool>? flags,
    AdminSettings? original,
  }) => SettingsFormState(
    name: name ?? this.name,
    password: password ?? this.password,
    clearPassword: clearPassword ?? this.clearPassword,
    numbers: numbers ?? this.numbers,
    joinPolicy: joinPolicy ?? this.joinPolicy,
    showdownReveal: showdownReveal ?? this.showdownReveal,
    variant: variant ?? this.variant,
    flags: flags ?? this.flags,
    original: original ?? this.original,
  );

  SettingsFormState setNumber(String field, String text) =>
      copyWith(numbers: {...numbers, field: text});
  SettingsFormState setFlag(String field, bool value) =>
      copyWith(flags: {...flags, field: value});

  int? number(String field) => int.tryParse(numbers[field]?.trim() ?? '');

  /// Validation mirroring §5.2 (the server re-validates).
  Map<String, SettingsError> validate({
    bool requireName = false,
    int seated = 0,
  }) {
    final errors = <String, SettingsError>{};
    for (final f in numericFields) {
      if (number(f) == null) {
        errors[f] = SettingsError.integer;
      }
    }
    if (requireName) {
      final n = name.trim();
      if (n.isEmpty || n.runes.length > 40) {
        errors['name'] = SettingsError.name;
      }
    }
    final pw = password;
    if (!clearPassword &&
        pw.isNotEmpty &&
        (pw.runes.length < 4 || pw.runes.length > 64)) {
      errors['password'] = SettingsError.password;
    }
    void check(String f, bool ok, SettingsError e) {
      if (!errors.containsKey(f) && !ok) {
        errors[f] = e;
      }
    }

    final mp = number('max_players') ?? 0;
    check(
      'max_players',
      mp >= 2 && mp <= 10 && mp >= seated,
      SettingsError.maxPlayers,
    );
    // A 20-card deck cannot serve more than six seats.
    check(
      'max_players',
      !isRoyal || mp <= royalMaxPlayers,
      SettingsError.maxPlayersRoyal,
    );
    final sm = number('start_money') ?? 0;
    check(
      'start_money',
      sm >= 1 && sm <= 1000000000000,
      SettingsError.startMoney,
    );
    final sb = number('small_blind') ?? 0;
    check('small_blind', sb >= 1, SettingsError.smallBlind);
    final bb = number('big_blind') ?? 0;
    check('big_blind', bb >= sb && bb >= 1, SettingsError.bigBlind);
    check('ante', (number('ante') ?? -1) >= 0, SettingsError.ante);
    final tt = number('turn_time') ?? 0;
    check('turn_time', tt >= 5 && tt <= 600, SettingsError.turnTime);
    final dt = number('disconnected_turn_time') ?? 0;
    check(
      'disconnected_turn_time',
      dt >= 3 && dt <= tt,
      SettingsError.disconnected,
    );
    final so = number('sit_out_after_missed_turns') ?? 0;
    check(
      'sit_out_after_missed_turns',
      so >= 1 && so <= 10,
      SettingsError.sitOut,
    );
    final hd = number('hand_delay_ms') ?? 0;
    check('hand_delay_ms', hd >= 2000 && hd <= 15000, SettingsError.handDelay);
    final bm = number('blinds_up_minutes') ?? 0;
    check(
      'blinds_up_minutes',
      bm >= 0 && bm <= 600,
      SettingsError.blindsUpMinutes,
    );
    final bp = number('blinds_up_percent') ?? 100;
    check(
      'blinds_up_percent',
      bp >= 10 && bp <= 400,
      SettingsError.blindsUpPercent,
    );
    final tb = number('time_bank_seconds') ?? 30;
    check('time_bank_seconds', tb >= 0 && tb <= 120, SettingsError.timeBank);
    final tr = number('time_bank_refill_seconds') ?? 1;
    check(
      'time_bank_refill_seconds',
      tr >= 0 && tr <= 30,
      SettingsError.timeBankRefill,
    );
    return errors;
  }

  /// Wire values of every field (for table creation).
  Map<String, Object?> toPatch({bool all = false}) {
    final patch = <String, Object?>{};
    final base = original.toFields();
    for (final f in numericFields) {
      final v = number(f);
      if (v != null && (all || v != base[f])) {
        patch[f] = v;
      }
    }
    if (all || joinPolicy != original.joinPolicy) {
      patch['join_policy'] = joinPolicy;
    }
    if (all || showdownReveal != original.showdownReveal) {
      patch['showdown_reveal'] = showdownReveal;
    }
    if (all || variant != original.variant) {
      patch['variant'] = variant;
    }
    for (final e in flags.entries) {
      if (all || e.value != base[e.key]) {
        patch[e.key] = e.value;
      }
    }
    if (clearPassword) {
      patch['password'] = '';
    } else if (password.isNotEmpty) {
      patch['password'] = password;
    }
    return patch;
  }

  bool get hasChanges => toPatch().isNotEmpty;
}
