import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../protocol/protocol.dart';
import 'providers.dart';
import 'session_store.dart';

/// What the server says about the viewer's own hand: how it is doing, and —
/// where the table allows it — the line the house strategy would take.
/// Everything in it comes from the asker's own cards and the public board.
class Strength {
  const Strength({
    this.street = '',
    required this.equity,
    required this.opponents,
    required this.tier,
    required this.description,
    required this.category,
    this.royal = false,
    this.advice,
  });

  factory Strength.fromJson(Map<String, dynamic> json) => Strength(
    street: json['street'] as String? ?? '',
    equity: (json['equity'] as num?)?.toDouble() ?? 0,
    opponents: json['opponents'] as int? ?? 0,
    tier: json['tier'] as String? ?? '',
    description: json['description'] as String? ?? '',
    category: json['category'] as int? ?? 0,
    royal: json['royal'] as bool? ?? false,
    advice: json['advice'] == null
        ? null
        : Advice.fromJson(json['advice'] as Map<String, dynamic>),
  );

  /// preflop | flop | turn | river — before the flop there is no board to
  /// have anything on, which changes what is worth saying.
  final String street;

  /// The share of the pot this hand takes against [opponents] random hands
  /// (0..1). Real opponents put money in with better than random hands, so
  /// it reads high — which is why the UI calls it "about".
  final double equity;
  final int opponents;

  /// monster | strong | good | marginal | weak, against an average holding.
  final String tier;
  final String description;
  final int category;
  final bool royal;
  final Advice? advice;
}

/// The strategy's line, with the price it weighed it against.
class Advice {
  const Advice({
    required this.action,
    this.amount = 0,
    this.sizing = '',
    this.reason = '',
    this.need = 0,
  });

  factory Advice.fromJson(Map<String, dynamic> json) => Advice(
    action: json['action'] as String? ?? '',
    amount: json['amount'] as int? ?? 0,
    sizing: json['sizing'] as String? ?? '',
    reason: json['reason'] as String? ?? '',
    need: (json['need'] as num?)?.toDouble() ?? 0,
  );

  /// fold | check | call | raise | all_in.
  final String action;

  /// The raise-to amount, for a raise.
  final int amount;

  /// "small" or "big" for a raise, empty otherwise — the size in the only
  /// terms a beginner can act on.
  final String sizing;

  /// Why this line, as an id the client has a sentence for. Named by the
  /// strategy where it decides, so it cannot drift from the decision.
  final String reason;

  /// The share of the time a call has to win to break even. Zero when
  /// checking is free.
  final double need;
}

/// Asks the server about the viewer's hand, once per spot. The spot is the
/// hand, the street and the price in front of the player: while those stay
/// the same the answer cannot change, and asking again would only spend the
/// rate limit and flicker the panel.
class StrengthNotifier extends Notifier<AsyncValue<Strength?>> {
  StrengthNotifier(this.tableId);

  final String tableId;
  String? _spot;
  int _request = 0;

  @override
  AsyncValue<Strength?> build() => const AsyncValue.data(null);

  /// Reads the spot the snapshot is in, or null when there is nothing to
  /// ask about: not the viewer's turn, or no hand.
  static String? spotOf(Snapshot? snap) {
    final you = snap?.you;
    final hand = snap?.hand;
    if (snap == null || you == null || hand == null) return null;
    if (you.options == null || you.seat == null) return null;
    return '${snap.table.handNumber}/${hand.street}/${you.options!.call}'
        '/${hand.currentBet}/${you.seat}';
  }

  /// Asks for this spot unless it is the one already answered.
  Future<void> ask(Snapshot? snap) async {
    final spot = spotOf(snap);
    if (spot == null) {
      _spot = null;
      state = const AsyncValue.data(null);
      return;
    }
    if (spot == _spot) return;
    _spot = spot;
    final token = ref.read(sessionProvider(tableId)).value?.token;
    if (token == null) {
      state = const AsyncValue.data(null);
      return;
    }
    final mine = ++_request;
    state = const AsyncValue.loading();
    try {
      final json = await ref
          .read(restClientProvider)
          .strength(tableId, token: token);
      if (mine != _request) return; // a newer spot overtook this answer
      state = AsyncValue.data(json == null ? null : Strength.fromJson(json));
    } on Object catch (e, st) {
      if (mine != _request) return;
      // A refusal is not worth a message: the table simply says nothing,
      // which is what an instance without the help looks like anyway.
      state = AsyncValue.error(e, st);
    }
  }
}

final strengthProvider =
    NotifierProvider.family<StrengthNotifier, AsyncValue<Strength?>, String>(
      StrengthNotifier.new,
    );
