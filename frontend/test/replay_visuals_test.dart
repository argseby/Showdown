import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/features/table/replay/replay_reducer.dart';
import 'package:showdown/protocol/protocol.dart';

import 'test_helpers.dart';

void main() {
  test('the replay presents one pot per step with amounts and spotlight', () {
    final events = [
      {
        'seq': 1,
        'ts': 1,
        'kind': 'hand_started',
        'button_seat': 4,
        'sb_seat': 4,
        'bb_seat': 0,
        'blinds': {'small': 50, 'big': 100},
        'ante': 0,
        'stacks': {'0': 10000, '4': 10000},
      },
      {
        'seq': 2,
        'ts': 1,
        'kind': 'hands_revealed',
        'reveals': [
          {
            'seat': 0,
            'cards': ['As', 'Kd'],
            'description': 'Pair of Aces',
            'best': ['As', 'Ah', 'Kd', '7c', '2d'],
          },
          {
            'seat': 4,
            'cards': ['Qh', 'Jh'],
            'description': 'Flush',
            'best': ['Qh', 'Jh', 'Ah', '7h', '2h'],
          },
        ],
      },
      {
        'seq': 3,
        'ts': 1,
        'kind': 'pot_awarded',
        'pot_index': 0,
        'seat': 0,
        'name': 'Alice',
        'amount': 300,
        'description': 'Pair of Aces',
      },
      {
        'seq': 4,
        'ts': 1,
        'kind': 'pot_awarded',
        'pot_index': 1,
        'seat': 4,
        'name': 'Bob',
        'amount': 100,
        'description': 'Flush',
      },
      {
        'seq': 5,
        'ts': 1,
        'kind': 'hand_ended',
        'results': {
          'pots': <Object>[],
          'seats': {
            '0': {'net': 200, 'won': 300, 'folded': false, 'revealed': true},
            '4': {'net': 40, 'won': 100, 'folded': false, 'revealed': true},
          },
        },
      },
    ].map(GameEvent.fromJson).toList();
    final reducer = ReplayReducer(
      events: events,
      base: fixtureSnapshot(),
      handNumber: 12,
      names: const {0: 'Alice', 4: 'Bob'},
      avatars: const {0: 0, 4: 0},
      viewerSeat: 0,
    );
    final afterReveal = reducer.frame(2);
    expect(afterReveal.potIndex, isNull);
    expect(afterReveal.winners, isEmpty);
    expect(afterReveal.revealed, {0, 4});

    final mainPot = reducer.frame(3);
    expect(mainPot.potIndex, 0);
    expect(mainPot.winners, {0});
    // The amount shown is the net gain from the results, not the pot.
    expect(mainPot.amounts, {0: 200});
    expect(mainPot.spotlight?.seat, 0);
    expect(mainPot.spotlight?.potIndex, 0);
    expect(mainPot.spotlight?.cards, ['As', 'Ah', 'Kd', '7c', '2d']);

    final sidePot = reducer.frame(4);
    expect(sidePot.potIndex, 1);
    expect(sidePot.winners, {4}); // only this pot's winner is on display
    expect(sidePot.amounts, {0: 200, 4: 40});
    expect(sidePot.spotlight?.seat, 4);
    expect(sidePot.spotlight?.description, 'Flush');

    final ended = reducer.frame(5);
    expect(ended.snapshot.hand?.phase, 'result');
    expect(ended.winners, {4});
  });
}
