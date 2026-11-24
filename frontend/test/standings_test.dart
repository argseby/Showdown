import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/core/standings.dart';
import 'package:showdown/protocol/protocol.dart';

AllTimeEntry _e(String name, int net, List<RoundLine> history) => AllTimeEntry(
  name: name,
  rounds: history.length,
  wins: 0,
  net: net,
  handsPlayed: 10,
  handsWon: 2,
  biggestPot: 300,
  history: history,
);

LeaderboardEntry _live(String name, int net, {int hands = 4}) =>
    LeaderboardEntry(
      name: name,
      stack: 1000 + net,
      net: net,
      handsWon: 1,
      biggestPot: 500,
      handsPlayed: hands,
    );

void main() {
  final record = [
    _e('Alice', 300, const [RoundLine(round: 1, net: 300)]),
    _e('Bob', -300, const [RoundLine(round: 1, net: -300)]),
  ];

  test('the round in progress moves the board before it ends', () {
    final merged = withLiveRound(record, [
      _live(' bob', 800),
      _live('Alice', -400),
      _live('Carol', -400),
    ], liveRound: 2);
    expect(merged.map((e) => e.name), ['Bob', 'Alice', 'Carol']);
    final bob = merged.first;
    expect(bob.net, 500);
    expect(bob.rounds, 2);
    expect(bob.handsPlayed, 14);
    expect(bob.biggestPot, 500);
    expect(bob.history.last, const RoundLine(round: 2, net: 800, handsWon: 1));
    expect(merged.last.history, hasLength(1));
  });

  test('a freshly opened round changes nothing', () {
    final merged = withLiveRound(record, [
      _live('Alice', 0, hands: 0).copyWith(handsWon: 0),
    ], liveRound: 2);
    expect(identical(merged, record), isTrue);
  });

  test('the chart carries a total through a round sat out', () {
    final entries = [
      _e('Alice', 500, const [
        RoundLine(round: 1, net: 300),
        RoundLine(round: 3, net: 200),
      ]),
      _e('Dan', -100, const [RoundLine(round: 2, net: -100)]),
    ];
    final s = netSeries(entries, [1, 2, 3]);
    expect(s[0].points, [300, 300, 500]);
    expect(s[1].points, [null, -100, -100]);
    expect(netSeries(entries, [1, 2, 3], top: 1), hasLength(1));
  });
}
