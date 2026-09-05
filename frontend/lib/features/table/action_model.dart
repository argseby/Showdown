import '../../protocol/protocol.dart';

/// Pure view model of the action bar for the current snapshot.
class ActionBarModel {
  const ActionBarModel({
    required this.canFold,
    required this.canCheck,
    required this.callAmount,
    required this.raise,
    required this.allIn,
    required this.isOpeningBet,
    required this.bigBlind,
    required this.potForPresets,
    required this.myBet,
  });

  /// Null when it is not the viewer's turn (buttons render disabled).
  static ActionBarModel? from(Snapshot s) {
    final o = s.you.options;
    final hand = s.hand;
    if (o == null || hand == null) return null;
    var pot = 0;
    for (final p in hand.pots) {
      pot += p.amount;
    }
    var myBet = 0;
    for (final sv in s.seats) {
      final p = sv.player;
      if (p == null) continue;
      pot += p.betThisStreet;
      if (sv.seat == s.you.seat) myBet = p.betThisStreet;
    }
    return ActionBarModel(
      canFold: o.fold,
      canCheck: o.check,
      callAmount: o.call,
      raise: o.raise,
      allIn: o.allIn,
      isOpeningBet: hand.currentBet == 0,
      bigBlind: s.table.settings.bigBlind,
      potForPresets: pot,
      myBet: myBet,
    );
  }

  final bool canFold;
  final bool canCheck;
  final int callAmount;
  final RaiseView? raise;
  final int allIn;
  final bool isOpeningBet;
  final int bigBlind;

  /// Chips in pots plus everything bet on the current street.
  final int potForPresets;
  final int myBet;

  bool get canCall => callAmount > 0;
  bool get canRaise => raise != null;
  bool get canAllIn => allIn > 0;

  /// Clamps a raise-to amount into the legal range.
  int clamp(int amount) {
    final r = raise;
    if (r == null) return amount;
    if (amount < r.min) return r.min;
    if (amount > r.max) return r.max;
    return amount;
  }

  /// Raise-to for a pot fraction (Min = 0, All-in = infinity), rounded down
  /// to a multiple of the big blind and clamped.
  int preset(double fraction) {
    final r = raise;
    if (r == null) return 0;
    if (fraction <= 0) return r.min;
    if (fraction.isInfinite) return r.max;
    final potAfterCall = potForPresets + callAmount;
    var target = myBet + callAmount + (fraction * potAfterCall).round();
    if (bigBlind > 0) target = target ~/ bigBlind * bigBlind;
    return clamp(target);
  }
}
