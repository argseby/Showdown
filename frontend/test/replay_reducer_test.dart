import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/features/table/replay/replay_reducer.dart';
import 'package:showdown/protocol/protocol.dart';

import 'test_helpers.dart';

void main() {
  test('replays a hand step by step from its events', () {
    final base = fixtureSnapshot();
    GameEvent ev(int seq, String kind, Map<String, dynamic> extra) =>
        GameEvent.fromJson({'seq': seq, 'ts': 0, 'kind': kind, ...extra});
    final events = [
      ev(1, 'hand_started', {
        'button_seat': 0,
        'sb_seat': 0,
        'bb_seat': 4,
        'stacks': {'0': 1000, '4': 1000},
      }),
      ev(2, 'blind_posted', {'seat': 0, 'blind': 'small', 'amount': 50}),
      ev(3, 'blind_posted', {'seat': 4, 'blind': 'big', 'amount': 100}),
      ev(4, 'hole_cards_dealt', {
        'seat': 0,
        'cards': ['As', 'Kd'],
      }),
      ev(5, 'hole_cards_dealt', {
        'seat': 4,
        'cards': ['Qs', 'Qd'],
      }),
      ev(6, 'action', {'seat': 0, 'action': 'raise', 'amount': 300}),
      ev(7, 'action', {'seat': 4, 'action': 'call', 'amount': 200}),
      ev(8, 'pots_updated', {
        'pots': [
          {
            'amount': 600,
            'eligible_seats': [0, 4],
          },
        ],
      }),
      ev(9, 'street_dealt', {
        'street': 'flop',
        'cards': ['2c', '7h', '9s'],
      }),
      ev(10, 'action', {'seat': 4, 'action': 'fold'}),
      ev(11, 'pot_awarded', {'pot_index': 0, 'seat': 0, 'amount': 600}),
      ev(12, 'hand_ended', {}),
      ev(13, 'rabbit_hunt', {
        'seat': 0,
        'cards': ['Jd', '3c'],
      }),
    ];
    final r = ReplayReducer(
      events: events,
      base: base,
      handNumber: 7,
      names: const {0: 'Alice', 4: 'Bob'},
      avatars: const {0: 1, 4: 2},
      viewerSeat: 0,
    );
    expect(r.frame(0).snapshot.hand, isNull);
    final afterBlinds = r.frame(3).snapshot;
    expect(afterBlinds.seats[0].player!.stack, 950);
    expect(afterBlinds.seats[4].player!.betThisStreet, 100);
    final afterRaise = r.frame(6).snapshot;
    expect(afterRaise.seats[0].player!.stack, 700);
    expect(afterRaise.seats[0].player!.betThisStreet, 300);
    expect(afterRaise.seats[0].player!.holeCards, ['As', 'Kd']);
    // Recorded (the hand went to showdown) but hidden until the reveal.
    expect(afterRaise.seats[4].player!.holeCards, isNull);
    final afterCall = r.frame(7).snapshot;
    expect(afterCall.seats[4].player!.stack, 700);
    final flop = r.frame(9).snapshot;
    expect(flop.hand!.board, ['2c', '7h', '9s']);
    expect(flop.hand!.pots.single.amount, 600);
    expect(flop.seats[0].player!.betThisStreet, 0);
    final folded = r.frame(10).snapshot;
    expect(folded.seats[4].player!.folded, isTrue);
    final end = r.frame(events.length);
    expect(end.snapshot.seats[0].player!.stack, 1300);
    expect(end.snapshot.hand!.phase, 'result');
    expect(end.snapshot.hand!.rabbitCards, ['Jd', '3c']);
    expect(end.winners, {0});
    expect(end.event!.kind, 'rabbit_hunt');
    // Chips are conserved at every step.
    for (var i = 1; i <= events.length; i++) {
      final s = r.frame(i).snapshot;
      var sum = 0;
      for (final sv in s.seats) {
        if (sv.player != null) {
          sum += sv.player!.stack + sv.player!.betThisStreet;
        }
      }
      for (final p in s.hand!.pots) {
        sum += p.amount;
      }
      if (i < 11) expect(sum, 2000, reason: 'step $i');
    }
  });
}
