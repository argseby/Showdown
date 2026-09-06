// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Envelope _$EnvelopeFromJson(Map<String, dynamic> json) => _Envelope(
  type: json['type'] as String,
  id: json['id'] as String?,
  payload: json['payload'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$EnvelopeToJson(_Envelope instance) => <String, dynamic>{
  'type': instance.type,
  'id': ?instance.id,
  'payload': ?instance.payload,
};

_ShowCardsPayload _$ShowCardsPayloadFromJson(Map<String, dynamic> json) =>
    _ShowCardsPayload(cards: json['cards'] as String?);

Map<String, dynamic> _$ShowCardsPayloadToJson(_ShowCardsPayload instance) =>
    <String, dynamic>{'cards': ?instance.cards};

_VoicePayload _$VoicePayloadFromJson(Map<String, dynamic> json) =>
    _VoicePayload(
      state: json['state'] as String,
      camera: json['camera'] as bool?,
    );

Map<String, dynamic> _$VoicePayloadToJson(_VoicePayload instance) =>
    <String, dynamic>{'state': instance.state, 'camera': ?instance.camera};

_VoiceSignal _$VoiceSignalFromJson(Map<String, dynamic> json) => _VoiceSignal(
  to: json['to'] as String?,
  from: json['from'] as String?,
  kind: json['kind'] as String,
  data: json['data'] as String,
);

Map<String, dynamic> _$VoiceSignalToJson(_VoiceSignal instance) =>
    <String, dynamic>{
      'to': ?instance.to,
      'from': ?instance.from,
      'kind': instance.kind,
      'data': instance.data,
    };

_StraddlePayload _$StraddlePayloadFromJson(Map<String, dynamic> json) =>
    _StraddlePayload(on: json['on'] as bool);

Map<String, dynamic> _$StraddlePayloadToJson(_StraddlePayload instance) =>
    <String, dynamic>{'on': instance.on};

_RunTwicePayload _$RunTwicePayloadFromJson(Map<String, dynamic> json) =>
    _RunTwicePayload(agree: json['agree'] as bool);

Map<String, dynamic> _$RunTwicePayloadToJson(_RunTwicePayload instance) =>
    <String, dynamic>{'agree': instance.agree};

_SayPayload _$SayPayloadFromJson(Map<String, dynamic> json) =>
    _SayPayload(phrase: json['phrase'] as String);

Map<String, dynamic> _$SayPayloadToJson(_SayPayload instance) =>
    <String, dynamic>{'phrase': instance.phrase};

_PhrasePayload _$PhrasePayloadFromJson(Map<String, dynamic> json) =>
    _PhrasePayload(
      seat: (json['seat'] as num).toInt(),
      name: json['name'] as String,
      phrase: json['phrase'] as String,
      ts: (json['ts'] as num).toInt(),
    );

Map<String, dynamic> _$PhrasePayloadToJson(_PhrasePayload instance) =>
    <String, dynamic>{
      'seat': instance.seat,
      'name': instance.name,
      'phrase': instance.phrase,
      'ts': instance.ts,
    };

_ChangeSeatPayload _$ChangeSeatPayloadFromJson(Map<String, dynamic> json) =>
    _ChangeSeatPayload(seat: (json['seat'] as num).toInt());

Map<String, dynamic> _$ChangeSeatPayloadToJson(_ChangeSeatPayload instance) =>
    <String, dynamic>{'seat': instance.seat};

_PreActionPayload _$PreActionPayloadFromJson(Map<String, dynamic> json) =>
    _PreActionPayload(kind: json['kind'] as String);

Map<String, dynamic> _$PreActionPayloadToJson(_PreActionPayload instance) =>
    <String, dynamic>{'kind': instance.kind};

_Hello _$HelloFromJson(Map<String, dynamic> json) => _Hello(
  v: (json['v'] as num).toInt(),
  token: json['token'] as String,
  adminToken: json['admin_token'] as String?,
);

Map<String, dynamic> _$HelloToJson(_Hello instance) => <String, dynamic>{
  'v': instance.v,
  'token': instance.token,
  'admin_token': ?instance.adminToken,
};

_ActionPayload _$ActionPayloadFromJson(Map<String, dynamic> json) =>
    _ActionPayload(
      kind: json['kind'] as String,
      amount: (json['amount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ActionPayloadToJson(_ActionPayload instance) =>
    <String, dynamic>{'kind': instance.kind, 'amount': ?instance.amount};

_ChatPayload _$ChatPayloadFromJson(Map<String, dynamic> json) =>
    _ChatPayload(text: json['text'] as String);

Map<String, dynamic> _$ChatPayloadToJson(_ChatPayload instance) =>
    <String, dynamic>{'text': instance.text};

_YouIdentity _$YouIdentityFromJson(Map<String, dynamic> json) => _YouIdentity(
  role: json['role'] as String,
  playerId: json['player_id'] as String?,
  seat: (json['seat'] as num?)?.toInt(),
);

Map<String, dynamic> _$YouIdentityToJson(_YouIdentity instance) =>
    <String, dynamic>{
      'role': instance.role,
      'player_id': ?instance.playerId,
      'seat': ?instance.seat,
    };

_Welcome _$WelcomeFromJson(Map<String, dynamic> json) => _Welcome(
  you: YouIdentity.fromJson(json['you'] as Map<String, dynamic>),
  snapshot: Snapshot.fromJson(json['snapshot'] as Map<String, dynamic>),
);

Map<String, dynamic> _$WelcomeToJson(_Welcome instance) => <String, dynamic>{
  'you': instance.you.toJson(),
  'snapshot': instance.snapshot.toJson(),
};

_Snapshot _$SnapshotFromJson(Map<String, dynamic> json) => _Snapshot(
  serverTs: (json['server_ts'] as num).toInt(),
  table: TableInfo.fromJson(json['table'] as Map<String, dynamic>),
  seats: (json['seats'] as List<dynamic>)
      .map((e) => SeatView.fromJson(e as Map<String, dynamic>))
      .toList(),
  hand: json['hand'] == null
      ? null
      : HandView.fromJson(json['hand'] as Map<String, dynamic>),
  you: You.fromJson(json['you'] as Map<String, dynamic>),
  leaderboard: (json['leaderboard'] as List<dynamic>)
      .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  spectators: (json['spectators'] as num).toInt(),
  spectatorNames: (json['spectator_names'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$SnapshotToJson(_Snapshot instance) => <String, dynamic>{
  'server_ts': instance.serverTs,
  'table': instance.table.toJson(),
  'seats': instance.seats.map((e) => e.toJson()).toList(),
  'hand': instance.hand?.toJson(),
  'you': instance.you.toJson(),
  'leaderboard': instance.leaderboard.map((e) => e.toJson()).toList(),
  'spectators': instance.spectators,
  'spectator_names': ?instance.spectatorNames,
};

_TableInfo _$TableInfoFromJson(Map<String, dynamic> json) => _TableInfo(
  id: json['id'] as String,
  name: json['name'] as String,
  state: json['state'] as String,
  handNumber: (json['hand_number'] as num).toInt(),
  settings: PublicSettings.fromJson(json['settings'] as Map<String, dynamic>),
  nextBlindsUpTs: (json['next_blinds_up_ts'] as num?)?.toInt(),
  nextHandTs: (json['next_hand_ts'] as num?)?.toInt(),
);

Map<String, dynamic> _$TableInfoToJson(_TableInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'state': instance.state,
      'hand_number': instance.handNumber,
      'settings': instance.settings.toJson(),
      'next_blinds_up_ts': ?instance.nextBlindsUpTs,
      'next_hand_ts': ?instance.nextHandTs,
    };

_PublicSettings _$PublicSettingsFromJson(Map<String, dynamic> json) =>
    _PublicSettings(
      smallBlind: (json['small_blind'] as num).toInt(),
      bigBlind: (json['big_blind'] as num).toInt(),
      ante: (json['ante'] as num).toInt(),
      turnTime: (json['turn_time'] as num).toInt(),
      maxPlayers: (json['max_players'] as num).toInt(),
      startMoney: (json['start_money'] as num).toInt(),
      joinPolicy: json['join_policy'] as String,
      allowRebuy: json['allow_rebuy'] as bool,
      showdownReveal: json['showdown_reveal'] as String,
      chatEnabled: json['chat_enabled'] as bool,
      spectatorChat: json['spectator_chat'] as bool,
      requiresPassword: json['requires_password'] as bool,
      allowRabbitHunt: json['allow_rabbit_hunt'] as bool,
      blindsUpMinutes: (json['blinds_up_minutes'] as num).toInt(),
      blindsUpPercent: (json['blinds_up_percent'] as num).toInt(),
      timeBankSeconds: (json['time_bank_seconds'] as num?)?.toInt() ?? 0,
      allowStraddle: json['allow_straddle'] as bool? ?? false,
      runItTwice: json['run_it_twice'] as bool? ?? false,
    );

Map<String, dynamic> _$PublicSettingsToJson(_PublicSettings instance) =>
    <String, dynamic>{
      'small_blind': instance.smallBlind,
      'big_blind': instance.bigBlind,
      'ante': instance.ante,
      'turn_time': instance.turnTime,
      'max_players': instance.maxPlayers,
      'start_money': instance.startMoney,
      'join_policy': instance.joinPolicy,
      'allow_rebuy': instance.allowRebuy,
      'showdown_reveal': instance.showdownReveal,
      'chat_enabled': instance.chatEnabled,
      'spectator_chat': instance.spectatorChat,
      'requires_password': instance.requiresPassword,
      'allow_rabbit_hunt': instance.allowRabbitHunt,
      'blinds_up_minutes': instance.blindsUpMinutes,
      'blinds_up_percent': instance.blindsUpPercent,
      'time_bank_seconds': instance.timeBankSeconds,
      'allow_straddle': instance.allowStraddle,
      'run_it_twice': instance.runItTwice,
    };

_SeatView _$SeatViewFromJson(Map<String, dynamic> json) => _SeatView(
  seat: (json['seat'] as num).toInt(),
  player: json['player'] == null
      ? null
      : PlayerView.fromJson(json['player'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SeatViewToJson(_SeatView instance) => <String, dynamic>{
  'seat': instance.seat,
  'player': instance.player?.toJson(),
};

_PlayerView _$PlayerViewFromJson(Map<String, dynamic> json) => _PlayerView(
  id: json['id'] as String,
  name: json['name'] as String,
  avatar: (json['avatar'] as num).toInt(),
  voice: json['voice'] as String? ?? 'off',
  muted: json['muted'] as bool?,
  mucked: json['mucked'] as bool?,
  camera: json['camera'] as bool?,
  equity: (json['equity'] as num?)?.toDouble(),
  timeBank: (json['time_bank'] as num?)?.toInt(),
  place: (json['place'] as num?)?.toInt(),
  stack: (json['stack'] as num).toInt(),
  status: json['status'] as String,
  connected: json['connected'] as bool,
  inHand: json['in_hand'] as bool,
  folded: json['folded'] as bool,
  allIn: json['all_in'] as bool,
  betThisStreet: (json['bet_this_street'] as num).toInt(),
  totalBet: (json['total_bet'] as num).toInt(),
  holeCards: (json['hole_cards'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  lastAction: json['last_action'] == null
      ? null
      : LastAction.fromJson(json['last_action'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PlayerViewToJson(_PlayerView instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatar': instance.avatar,
      'voice': instance.voice,
      'muted': ?instance.muted,
      'mucked': ?instance.mucked,
      'camera': ?instance.camera,
      'equity': ?instance.equity,
      'time_bank': ?instance.timeBank,
      'place': ?instance.place,
      'stack': instance.stack,
      'status': instance.status,
      'connected': instance.connected,
      'in_hand': instance.inHand,
      'folded': instance.folded,
      'all_in': instance.allIn,
      'bet_this_street': instance.betThisStreet,
      'total_bet': instance.totalBet,
      'hole_cards': ?instance.holeCards,
      'last_action': instance.lastAction?.toJson(),
    };

_LastAction _$LastActionFromJson(Map<String, dynamic> json) => _LastAction(
  kind: json['kind'] as String,
  amount: (json['amount'] as num).toInt(),
);

Map<String, dynamic> _$LastActionToJson(_LastAction instance) =>
    <String, dynamic>{'kind': instance.kind, 'amount': instance.amount};

_HandView _$HandViewFromJson(Map<String, dynamic> json) => _HandView(
  street: json['street'] as String,
  board: (json['board'] as List<dynamic>).map((e) => e as String).toList(),
  buttonSeat: (json['button_seat'] as num).toInt(),
  sbSeat: (json['sb_seat'] as num).toInt(),
  bbSeat: (json['bb_seat'] as num).toInt(),
  toActSeat: (json['to_act_seat'] as num?)?.toInt(),
  deadlineTs: (json['deadline_ts'] as num?)?.toInt(),
  currentBet: (json['current_bet'] as num).toInt(),
  minRaiseTo: (json['min_raise_to'] as num).toInt(),
  pots: (json['pots'] as List<dynamic>)
      .map((e) => PotView.fromJson(e as Map<String, dynamic>))
      .toList(),
  phase: json['phase'] as String,
  rabbitCards: (json['rabbit_cards'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  phaseEndsTs: (json['phase_ends_ts'] as num?)?.toInt(),
  board2: (json['board2'] as List<dynamic>?)?.map((e) => e as String).toList(),
  straddleSeat: (json['straddle_seat'] as num?)?.toInt(),
  timeBankActive: json['time_bank_active'] as bool?,
  runTwice: json['run_twice'] as bool?,
  runTwiceEndsTs: (json['run_twice_ends_ts'] as num?)?.toInt(),
);

Map<String, dynamic> _$HandViewToJson(_HandView instance) => <String, dynamic>{
  'street': instance.street,
  'board': instance.board,
  'button_seat': instance.buttonSeat,
  'sb_seat': instance.sbSeat,
  'bb_seat': instance.bbSeat,
  'to_act_seat': instance.toActSeat,
  'deadline_ts': instance.deadlineTs,
  'current_bet': instance.currentBet,
  'min_raise_to': instance.minRaiseTo,
  'pots': instance.pots.map((e) => e.toJson()).toList(),
  'phase': instance.phase,
  'rabbit_cards': ?instance.rabbitCards,
  'phase_ends_ts': ?instance.phaseEndsTs,
  'board2': ?instance.board2,
  'straddle_seat': ?instance.straddleSeat,
  'time_bank_active': ?instance.timeBankActive,
  'run_twice': ?instance.runTwice,
  'run_twice_ends_ts': ?instance.runTwiceEndsTs,
};

_PotView _$PotViewFromJson(Map<String, dynamic> json) => _PotView(
  amount: (json['amount'] as num).toInt(),
  eligibleSeats: (json['eligible_seats'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$PotViewToJson(_PotView instance) => <String, dynamic>{
  'amount': instance.amount,
  'eligible_seats': instance.eligibleSeats,
};

_You _$YouFromJson(Map<String, dynamic> json) => _You(
  role: json['role'] as String,
  isAdmin: json['is_admin'] as bool,
  playerId: json['player_id'] as String?,
  seat: (json['seat'] as num?)?.toInt(),
  options: json['options'] == null
      ? null
      : OptionsView.fromJson(json['options'] as Map<String, dynamic>),
  handDescription: json['hand_description'] as String,
  canRebuy: json['can_rebuy'] as bool,
  canShowCards: json['can_show_cards'] as bool,
  preAction: json['pre_action'] as String,
  bestCards: (json['best_cards'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  canRabbitHunt: json['can_rabbit_hunt'] as bool,
  pendingSeat: (json['pending_seat'] as num?)?.toInt(),
  canChangeSeat: json['can_change_seat'] as bool? ?? false,
  straddle: json['straddle'] as bool?,
  canRunTwice: json['can_run_twice'] as bool?,
  runTwiceVote: json['run_twice_vote'] as bool?,
);

Map<String, dynamic> _$YouToJson(_You instance) => <String, dynamic>{
  'role': instance.role,
  'is_admin': instance.isAdmin,
  'player_id': ?instance.playerId,
  'seat': ?instance.seat,
  'options': instance.options?.toJson(),
  'hand_description': instance.handDescription,
  'can_rebuy': instance.canRebuy,
  'can_show_cards': instance.canShowCards,
  'pre_action': instance.preAction,
  'best_cards': ?instance.bestCards,
  'can_rabbit_hunt': instance.canRabbitHunt,
  'pending_seat': ?instance.pendingSeat,
  'can_change_seat': instance.canChangeSeat,
  'straddle': ?instance.straddle,
  'can_run_twice': ?instance.canRunTwice,
  'run_twice_vote': ?instance.runTwiceVote,
};

_OptionsView _$OptionsViewFromJson(Map<String, dynamic> json) => _OptionsView(
  fold: json['fold'] as bool,
  check: json['check'] as bool,
  call: (json['call'] as num).toInt(),
  raise: json['raise'] == null
      ? null
      : RaiseView.fromJson(json['raise'] as Map<String, dynamic>),
  allIn: (json['all_in'] as num).toInt(),
);

Map<String, dynamic> _$OptionsViewToJson(_OptionsView instance) =>
    <String, dynamic>{
      'fold': instance.fold,
      'check': instance.check,
      'call': instance.call,
      'raise': instance.raise?.toJson(),
      'all_in': instance.allIn,
    };

_RaiseView _$RaiseViewFromJson(Map<String, dynamic> json) => _RaiseView(
  min: (json['min'] as num).toInt(),
  max: (json['max'] as num).toInt(),
);

Map<String, dynamic> _$RaiseViewToJson(_RaiseView instance) =>
    <String, dynamic>{'min': instance.min, 'max': instance.max};

_LeaderboardEntry _$LeaderboardEntryFromJson(Map<String, dynamic> json) =>
    _LeaderboardEntry(
      name: json['name'] as String,
      stack: (json['stack'] as num).toInt(),
      net: (json['net'] as num).toInt(),
      handsWon: (json['hands_won'] as num).toInt(),
      biggestPot: (json['biggest_pot'] as num).toInt(),
      handsPlayed: (json['hands_played'] as num?)?.toInt(),
      vpipHands: (json['vpip_hands'] as num?)?.toInt(),
      showdowns: (json['showdowns'] as num?)?.toInt(),
      showdownsWon: (json['showdowns_won'] as num?)?.toInt(),
      place: (json['place'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LeaderboardEntryToJson(_LeaderboardEntry instance) =>
    <String, dynamic>{
      'name': instance.name,
      'stack': instance.stack,
      'net': instance.net,
      'hands_won': instance.handsWon,
      'biggest_pot': instance.biggestPot,
      'hands_played': ?instance.handsPlayed,
      'vpip_hands': ?instance.vpipHands,
      'showdowns': ?instance.showdowns,
      'showdowns_won': ?instance.showdownsWon,
      'place': ?instance.place,
    };

_EventsPayload _$EventsPayloadFromJson(Map<String, dynamic> json) =>
    _EventsPayload(
      handNumber: (json['hand_number'] as num).toInt(),
      events: (json['events'] as List<dynamic>)
          .map((e) => GameEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EventsPayloadToJson(_EventsPayload instance) =>
    <String, dynamic>{
      'hand_number': instance.handNumber,
      'events': instance.events.map((e) => e.toJson()).toList(),
    };

_GameEvent _$GameEventFromJson(Map<String, dynamic> json) => _GameEvent(
  seq: (json['seq'] as num).toInt(),
  ts: (json['ts'] as num).toInt(),
  kind: json['kind'] as String,
  seat: (json['seat'] as num?)?.toInt(),
  name: json['name'] as String?,
  amount: (json['amount'] as num?)?.toInt(),
  delta: (json['delta'] as num?)?.toInt(),
  allIn: json['all_in'] as bool?,
  action: json['action'] as String?,
  blind: json['blind'] as String?,
  resolvedAs: json['resolved_as'] as String?,
  street: json['street'] as String?,
  cards: (json['cards'] as List<dynamic>?)?.map((e) => e as String).toList(),
  pots: (json['pots'] as List<dynamic>?)
      ?.map((e) => PotView.fromJson(e as Map<String, dynamic>))
      .toList(),
  reveals: (json['reveals'] as List<dynamic>?)
      ?.map((e) => Reveal.fromJson(e as Map<String, dynamic>))
      .toList(),
  potIndex: (json['pot_index'] as num?)?.toInt(),
  board: (json['board'] as num?)?.toInt(),
  description: json['description'] as String?,
  results: json['results'] == null
      ? null
      : HandResults.fromJson(json['results'] as Map<String, dynamic>),
  reason: json['reason'] as String?,
  fields: (json['fields'] as List<dynamic>?)?.map((e) => e as String).toList(),
  buttonSeat: (json['button_seat'] as num?)?.toInt(),
  sbSeat: (json['sb_seat'] as num?)?.toInt(),
  bbSeat: (json['bb_seat'] as num?)?.toInt(),
  blinds: json['blinds'] == null
      ? null
      : Blinds.fromJson(json['blinds'] as Map<String, dynamic>),
  ante: (json['ante'] as num?)?.toInt(),
  stacks: (json['stacks'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, (e as num).toInt()),
  ),
);

Map<String, dynamic> _$GameEventToJson(_GameEvent instance) =>
    <String, dynamic>{
      'seq': instance.seq,
      'ts': instance.ts,
      'kind': instance.kind,
      'seat': ?instance.seat,
      'name': ?instance.name,
      'amount': ?instance.amount,
      'delta': ?instance.delta,
      'all_in': ?instance.allIn,
      'action': ?instance.action,
      'blind': ?instance.blind,
      'resolved_as': ?instance.resolvedAs,
      'street': ?instance.street,
      'cards': ?instance.cards,
      'pots': ?instance.pots?.map((e) => e.toJson()).toList(),
      'reveals': ?instance.reveals?.map((e) => e.toJson()).toList(),
      'pot_index': ?instance.potIndex,
      'board': ?instance.board,
      'description': ?instance.description,
      'results': ?instance.results?.toJson(),
      'reason': ?instance.reason,
      'fields': ?instance.fields,
      'button_seat': ?instance.buttonSeat,
      'sb_seat': ?instance.sbSeat,
      'bb_seat': ?instance.bbSeat,
      'blinds': ?instance.blinds?.toJson(),
      'ante': ?instance.ante,
      'stacks': ?instance.stacks,
    };

_Blinds _$BlindsFromJson(Map<String, dynamic> json) => _Blinds(
  small: (json['small'] as num).toInt(),
  big: (json['big'] as num).toInt(),
);

Map<String, dynamic> _$BlindsToJson(_Blinds instance) => <String, dynamic>{
  'small': instance.small,
  'big': instance.big,
};

_Reveal _$RevealFromJson(Map<String, dynamic> json) => _Reveal(
  seat: (json['seat'] as num).toInt(),
  cards: (json['cards'] as List<dynamic>).map((e) => e as String).toList(),
  description: json['description'] as String,
  best: (json['best'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$RevealToJson(_Reveal instance) => <String, dynamic>{
  'seat': instance.seat,
  'cards': instance.cards,
  'description': instance.description,
  'best': ?instance.best,
};

_HandResults _$HandResultsFromJson(Map<String, dynamic> json) => _HandResults(
  pots: (json['pots'] as List<dynamic>)
      .map((e) => PotResult.fromJson(e as Map<String, dynamic>))
      .toList(),
  seats: (json['seats'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, SeatResult.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$HandResultsToJson(_HandResults instance) =>
    <String, dynamic>{
      'pots': instance.pots.map((e) => e.toJson()).toList(),
      'seats': instance.seats.map((k, e) => MapEntry(k, e.toJson())),
    };

_PotResult _$PotResultFromJson(Map<String, dynamic> json) => _PotResult(
  index: (json['index'] as num).toInt(),
  amount: (json['amount'] as num).toInt(),
  winners: (json['winners'] as List<dynamic>)
      .map((e) => PotWinner.fromJson(e as Map<String, dynamic>))
      .toList(),
  description: json['description'] as String,
);

Map<String, dynamic> _$PotResultToJson(_PotResult instance) =>
    <String, dynamic>{
      'index': instance.index,
      'amount': instance.amount,
      'winners': instance.winners.map((e) => e.toJson()).toList(),
      'description': instance.description,
    };

_PotWinner _$PotWinnerFromJson(Map<String, dynamic> json) => _PotWinner(
  seat: (json['seat'] as num).toInt(),
  amount: (json['amount'] as num).toInt(),
);

Map<String, dynamic> _$PotWinnerToJson(_PotWinner instance) =>
    <String, dynamic>{'seat': instance.seat, 'amount': instance.amount};

_SeatResult _$SeatResultFromJson(Map<String, dynamic> json) => _SeatResult(
  net: (json['net'] as num).toInt(),
  won: (json['won'] as num).toInt(),
  folded: json['folded'] as bool,
  revealed: json['revealed'] as bool,
  cards: (json['cards'] as List<dynamic>?)?.map((e) => e as String).toList(),
  description: json['description'] as String?,
  best: (json['best'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$SeatResultToJson(_SeatResult instance) =>
    <String, dynamic>{
      'net': instance.net,
      'won': instance.won,
      'folded': instance.folded,
      'revealed': instance.revealed,
      'cards': ?instance.cards,
      'description': ?instance.description,
      'best': ?instance.best,
    };

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  id: (json['id'] as num).toInt(),
  authorKind: json['author_kind'] as String,
  authorName: json['author_name'] as String,
  text: json['text'] as String,
  ts: (json['ts'] as num).toInt(),
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author_kind': instance.authorKind,
      'author_name': instance.authorName,
      'text': instance.text,
      'ts': instance.ts,
    };

_ChatHistory _$ChatHistoryFromJson(Map<String, dynamic> json) => _ChatHistory(
  messages: (json['messages'] as List<dynamic>)
      .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ChatHistoryToJson(_ChatHistory instance) =>
    <String, dynamic>{
      'messages': instance.messages.map((e) => e.toJson()).toList(),
    };

_ChatRemoved _$ChatRemovedFromJson(Map<String, dynamic> json) =>
    _ChatRemoved(id: (json['id'] as num).toInt());

Map<String, dynamic> _$ChatRemovedToJson(_ChatRemoved instance) =>
    <String, dynamic>{'id': instance.id};

_Ack _$AckFromJson(Map<String, dynamic> json) => _Ack(id: json['id'] as String);

Map<String, dynamic> _$AckToJson(_Ack instance) => <String, dynamic>{
  'id': instance.id,
};

_ErrorPayload _$ErrorPayloadFromJson(Map<String, dynamic> json) =>
    _ErrorPayload(
      id: json['id'] as String?,
      code: json['code'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$ErrorPayloadToJson(_ErrorPayload instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'code': instance.code,
      'message': instance.message,
    };

_Kicked _$KickedFromJson(Map<String, dynamic> json) =>
    _Kicked(reason: json['reason'] as String);

Map<String, dynamic> _$KickedToJson(_Kicked instance) => <String, dynamic>{
  'reason': instance.reason,
};

_TableEnded _$TableEndedFromJson(Map<String, dynamic> json) => _TableEnded(
  finalLeaderboard: (json['final_leaderboard'] as List<dynamic>)
      .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TableEndedToJson(_TableEnded instance) =>
    <String, dynamic>{
      'final_leaderboard': instance.finalLeaderboard
          .map((e) => e.toJson())
          .toList(),
    };

_Pong _$PongFromJson(Map<String, dynamic> json) =>
    _Pong(serverTs: (json['server_ts'] as num).toInt());

Map<String, dynamic> _$PongToJson(_Pong instance) => <String, dynamic>{
  'server_ts': instance.serverTs,
};
