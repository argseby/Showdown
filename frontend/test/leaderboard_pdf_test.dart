import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/features/table/leaderboard_pdf.dart';
import 'package:showdown/protocol/protocol.dart';

final _texts = LeaderboardPdfTexts(
  title: 'Leaderboard',
  generated: 'Exported 19 Nov 2026 21:04',
  allTime: 'All time',
  allTimeNote: 'Every finished round at this table, added up.',
  thisRound: 'This round',
  round: (i) => 'Round $i',
  hands: (n) => '$n hands',
  noRounds: 'No round has finished yet.',
  colRank: '#',
  colPlayer: 'Player',
  colRounds: 'Rounds',
  colWins: 'Wins',
  colNet: 'Net',
  colStack: 'Stack',
  colHands: 'Hands',
  colHandsWon: 'Hands won',
  colBiggestPot: 'Biggest pot',
  bot: 'bot',
  chartTitle: 'Net over the rounds',
  biggestPot: (amount, names, hand) =>
      'Biggest pot $amount: $names, hand #$hand',
);

LeaderboardEntry _entry(String name, {int net = 0, int place = 0}) =>
    LeaderboardEntry(
      name: name,
      stack: 3000 + net,
      net: net,
      handsWon: 3,
      biggestPot: 900,
      handsPlayed: 12,
      place: place == 0 ? null : place,
    );

TableStandings _standings(List<AllTimeEntry> allTime) => TableStandings(
  tableId: 't1',
  tableName: 'Kitchen table',
  allTime: allTime,
  rounds: [
    RoundStanding(
      index: 1,
      roundStart: 0,
      hands: 18,
      endedAt: 1763500000000,
      bigBlind: 100,
      standings: [
        _entry('Alice', net: 1500, place: 1),
        _entry('Bob', net: -1500, place: 2),
      ],
      biggestPot: const RoundHighlight(
        hand: 12,
        amount: 2400,
        winners: ['Alice', 'Bob 🎲'],
        description: 'Full House',
      ),
    ),
    RoundStanding(
      index: 2,
      roundStart: 18,
      hands: 24,
      endedAt: 1763600000000,
      bigBlind: 100,
      standings: [
        _entry('Bob', net: 2000, place: 1),
        _entry('Alice', net: -2000, place: 2),
      ],
    ),
  ],
);

AllTimeEntry _allTime(String name, {int net = 500, bool bot = false}) =>
    AllTimeEntry(
      name: name,
      rounds: 2,
      wins: 1,
      net: net,
      handsPlayed: 42,
      handsWon: 9,
      biggestPot: 2500,
      bot: bot,
      history: [
        RoundLine(round: 1, net: net * 3),
        RoundLine(round: 2, net: -net * 2),
      ],
    );

void main() {
  test('prints a PDF with the all-time board and every round', () async {
    final bytes = await buildLeaderboardPdf(
      tableName: 'Kitchen table',
      standings: _standings([_allTime('Alice'), _allTime('Bob', net: -500)]),
      current: [_entry('Alice', net: 200), _entry('Bob', net: -200)],
      texts: _texts,
      amount: (v) => '$v',
      date: (ts) => '19 Nov 2026',
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    // The board, the chart, the live round and both rounds.
    expect(bytes.length, greaterThan(4000));
  });

  test('exports with nothing played yet', () async {
    final bytes = await buildLeaderboardPdf(
      tableName: 'Fresh table',
      standings: null,
      current: const [],
      texts: _texts,
      amount: (v) => '$v',
      date: (ts) => '19 Nov 2026',
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('survives names the built-in font cannot draw', () async {
    // Helvetica throws on anything outside Latin-1, and a player name is
    // free text: emoji and other scripts must not take the export down.
    final bytes = await buildLeaderboardPdf(
      tableName: 'Tisch 🃏',
      standings: _standings([_allTime('🂡 Łukasz'), _allTime('なまえ')]),
      current: [_entry('Grüße 🎉')],
      texts: _texts,
      amount: (v) => '$v',
      date: (ts) => '19 Nov 2026',
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
