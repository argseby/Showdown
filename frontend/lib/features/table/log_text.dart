import '../../core/formatting.dart';
import '../../l10n/app_localizations.dart';
import '../../protocol/protocol.dart';
import 'table_session.dart';

/// Localized label for a pot index.
String potLabel(AppLocalizations l, int index) =>
    index == 0 ? l.mainPot : l.sidePot(index);

/// Renders one log entry, or null for events that have no line.
String? logLineText(
  AppLocalizations l,
  LogEntry entry, {
  int? mySeat,
  String locale = 'en',
  String Function(int amount)? amount,
}) {
  final e = entry.event;
  String name([int? seat]) {
    final s = seat ?? e.seat;
    if (e.name != null && e.name!.isNotEmpty) return e.name!;
    if (s == null) return '?';
    return entry.names[s] ?? l.seatLabel(s);
  }

  String chips(int? v) =>
      amount == null ? formatChips(v ?? 0, locale) : amount(v ?? 0);
  final allIn = e.allIn == true ? l.logAllInSuffix : '';

  switch (e.kind) {
    case 'hand_started':
      return l.logHandStarted(entry.handNumber, name(e.buttonSeat));
    case 'ante_posted':
      return l.logAnte(name(), chips(e.amount));
    case 'blind_posted':
      return switch (e.blind) {
        'small' => l.logSmallBlind(name(), chips(e.amount)),
        'dead' => l.logDeadBlind(name(), chips(e.amount)),
        _ => l.logBigBlind(name(), chips(e.amount)),
      };
    case 'hole_cards_dealt':
      if (e.cards == null || e.seat != mySeat) return null;
      return l.logDealt(prettyCards(e.cards!));
    case 'action':
      switch (e.action) {
        case 'fold':
          return l.logFold(name());
        case 'check':
          return l.logCheck(name());
        case 'call':
          return l.logCall(name(), chips(e.amount)) + allIn;
        case 'bet':
          return l.logBet(name(), chips(e.amount)) + allIn;
        case 'raise':
          return l.logRaise(name(), chips(e.amount)) + allIn;
      }
      return null;
    case 'timeout':
      return e.resolvedAs == 'check'
          ? l.logTimeoutCheck(name())
          : l.logTimeoutFold(name());
    case 'uncalled_returned':
      return l.logUncalled(chips(e.amount), name());
    case 'street_dealt':
      final cards = prettyCards(e.cards ?? const []);
      switch (e.street) {
        case 'flop':
          return l.logFlop(cards);
        case 'turn':
          return l.logTurn(cards);
        default:
          return l.logRiver(cards);
      }
    case 'hands_revealed':
      final lines = <String>[];
      for (final r in e.reveals ?? const <Reveal>[]) {
        final n = entry.names[r.seat] ?? l.seatLabel(r.seat);
        lines.add(
          r.description.isEmpty
              ? l.logRevealNoDesc(n, prettyCards(r.cards))
              : l.logReveal(n, prettyCards(r.cards), r.description),
        );
      }
      return lines.isEmpty ? null : lines.join('\n');
    case 'pot_awarded':
      final pot = potLabel(l, e.potIndex ?? 0);
      final desc = e.description ?? '';
      return desc.isEmpty
          ? l.logWinUncontested(name(), chips(e.amount), pot)
          : l.logWin(name(), chips(e.amount), pot, desc);
    case 'mucked':
      return l.logMucks(name());
    case 'player_moved':
      return l.logPlayerMoved(name(), (e.seat ?? 0) + 1);
    case 'rabbit_hunt':
      return l.logRabbitHunt(name(), prettyCards(e.cards ?? const []));
    case 'blinds_changed':
      return l.logBlindsChanged(chips(e.blinds?.small), chips(e.blinds?.big));
    case 'hand_voided':
      return l.logVoided(e.reason ?? '');
    case 'player_joined':
      return l.logJoined(name(), e.seat ?? 0);
    case 'player_left':
      return l.logLeft(name());
    case 'player_kicked':
      return l.logKicked(name());
    case 'player_sat_out':
      return l.logSatOut(name());
    case 'player_sat_in':
      return l.logSatIn(name());
    case 'player_busted':
      return l.logBusted(name());
    case 'player_rebought':
      return l.logRebought(name(), chips(e.amount));
    case 'chips_adjusted':
      final d = e.delta ?? 0;
      return l.logChips(name(), (d > 0 ? '+' : '') + chips(d));
    case 'settings_changed':
      return l.logSettings((e.fields ?? const []).join(', '));
    case 'table_started':
      return l.logStarted;
    case 'table_paused':
      return l.logPaused;
    case 'table_resumed':
      return l.logResumed;
    case 'table_ended':
      return l.logEnded;
  }
  return null;
}
