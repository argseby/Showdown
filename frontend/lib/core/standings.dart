import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../protocol/protocol.dart';
import 'providers.dart';

/// Which table's record to read, and with which token. The token is part of
/// the key on purpose: the host reads the same table with its admin token
/// and a player with their session token, and neither is derivable from the
/// other here.
typedef StandingsKey = ({String tableId, String token});

/// The table's whole record: every round it has finished and the all-time
/// totals summed from them. Unlike the live leaderboard this does not ride
/// along in the snapshot — it only changes when a round ends, so it is
/// fetched when somebody looks and invalidated when the table says a round
/// is over.
final tableStandingsProvider =
    FutureProvider.family<TableStandings, StandingsKey>((ref, key) async {
      return ref
          .read(restClientProvider)
          .standings(key.tableId, token: key.token);
    });

/// The key a player is matched by across the record and the live round:
/// the name, trimmed and lower-cased, as the server does for guests.
String standingsNameKey(String name) => name.trim().toLowerCase();

/// Whether the round being played has anything to add yet: a hand dealt or
/// a chip moved. A freshly opened round is all zeros and changes nothing.
bool liveRoundHasPlay(List<LeaderboardEntry> live) =>
    live.any((e) => (e.handsPlayed ?? 0) > 0 || e.handsWon > 0 || e.net != 0);

/// [base] with the round being played added on top: provisional totals that
/// move hand by hand instead of waiting for the round to end. The live round
/// gets [liveRound] as its index in each player's history. A player of the
/// live round is matched to the record by name; one who is new to the table
/// gets a line of their own. Sorted like the server sorts the board.
List<AllTimeEntry> withLiveRound(
  List<AllTimeEntry> base,
  List<LeaderboardEntry> live, {
  required int liveRound,
  Map<String, int> avatars = const {},
}) {
  if (!liveRoundHasPlay(live)) return base;
  final out = [...base];
  final index = {
    for (var i = 0; i < out.length; i++) standingsNameKey(out[i].name): i,
  };
  for (final l in live) {
    final line = RoundLine(
      round: liveRound,
      net: l.net,
      place: l.place ?? 0,
      handsWon: l.handsWon,
    );
    final i = index[standingsNameKey(l.name)];
    if (i == null) {
      index[standingsNameKey(l.name)] = out.length;
      out.add(
        AllTimeEntry(
          name: l.name,
          avatar: avatars[l.name] ?? 0,
          rounds: 1,
          wins: 0,
          net: l.net,
          handsPlayed: l.handsPlayed ?? 0,
          handsWon: l.handsWon,
          biggestPot: l.biggestPot,
          vpipHands: l.vpipHands ?? 0,
          showdowns: l.showdowns ?? 0,
          showdownsWon: l.showdownsWon ?? 0,
          history: [line],
        ),
      );
      continue;
    }
    final e = out[i];
    out[i] = e.copyWith(
      rounds: e.rounds + 1,
      net: e.net + l.net,
      handsPlayed: e.handsPlayed + (l.handsPlayed ?? 0),
      handsWon: e.handsWon + l.handsWon,
      biggestPot: l.biggestPot > e.biggestPot ? l.biggestPot : e.biggestPot,
      vpipHands: e.vpipHands + (l.vpipHands ?? 0),
      showdowns: e.showdowns + (l.showdowns ?? 0),
      showdownsWon: e.showdownsWon + (l.showdownsWon ?? 0),
      history: [...e.history, line],
    );
  }
  out.sort((a, b) {
    if (a.net != b.net) return b.net.compareTo(a.net);
    if (a.wins != b.wins) return b.wins.compareTo(a.wins);
    if (a.rounds != b.rounds) return b.rounds.compareTo(a.rounds);
    return standingsNameKey(a.name).compareTo(standingsNameKey(b.name));
  });
  return out;
}

/// One player's line in the chart of the board over the rounds.
class NetSeries {
  const NetSeries({required this.name, required this.points});
  final String name;

  /// Running total after each round, one per entry of the chart's rounds
  /// (null before the player's first round there).
  final List<int?> points;
}

/// The running net of the [top] players of [entries] over [rounds] (round
/// indexes, ascending). A player who sat a round out keeps their total
/// through it; before their first round they have no point.
List<NetSeries> netSeries(
  List<AllTimeEntry> entries,
  List<int> rounds, {
  int top = 6,
}) {
  final out = <NetSeries>[];
  for (final e in entries.take(top)) {
    final byRound = {for (final h in e.history) h.round: h.net};
    var total = 0;
    var started = false;
    final points = <int?>[];
    for (final r in rounds) {
      final net = byRound[r];
      if (net != null) {
        total += net;
        started = true;
      }
      points.add(started ? total : null);
    }
    out.add(NetSeries(name: e.name, points: points));
  }
  return out;
}
