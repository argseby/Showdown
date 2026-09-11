import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/core/ws_transport.dart';
import 'package:showdown/features/table/table_session.dart';

import 'test_helpers.dart';

class _Transport implements WsTransport {
  final controller = StreamController<String>.broadcast();
  @override
  Future<void> connect() async {}
  @override
  Stream<String> get messages => controller.stream;
  @override
  void send(String data) {
    final env = jsonDecode(data) as Map<String, dynamic>;
    if (env['type'] == 'hello') {
      push('welcome', {
        'you': {'role': 'player', 'player_id': 'p1', 'seat': 0},
        'snapshot': fixtureSnapshot().toJson(),
      });
    } else if (env['id'] != null) {
      push('ack', {'id': env['id']});
    }
  }

  void push(String type, Map<String, dynamic> payload) =>
      controller.add(jsonEncode({'type': type, 'payload': payload}));
  @override
  Future<void> close([int code = 1000, String? reason]) => controller.close();
  @override
  int? get closeCode => null;
  @override
  String? get closeReason => null;
}

void main() {
  late _Transport transport;
  late ProviderContainer container;
  setUp(() {
    transport = _Transport();
    TableSessionNotifier.transportFactoryOverride = (_) => transport;
    TableSessionNotifier.urlOverride = (id) => Uri.parse('ws://test/$id');
    container = ProviderContainer();
  });
  tearDown(() {
    TableSessionNotifier.transportFactoryOverride = null;
    TableSessionNotifier.urlOverride = null;
  });

  /// Disposes the session before the test ends so that the client's
  /// keepalive timer does not count as a pending timer.
  Future<void> finish(WidgetTester tester) async {
    container.dispose();
    await tester.pump();
  }

  Map<String, Object?> award(int pot, int seat, String name, String desc) => {
    'seq': 40 + pot,
    'ts': 1,
    'kind': 'pot_awarded',
    'pot_index': pot,
    'seat': seat,
    'name': name,
    'amount': 100 * (pot + 1),
    'description': desc,
  };

  testWidgets('a split pot spotlights every tied winner', (tester) async {
    container.read(tableSessionProvider('t1').notifier).start('tok');
    await tester.pump();
    transport.push('events', {
      'hand_number': 12,
      'events': [
        award(0, 0, 'Alice', 'Straight, Ten high'),
        {...award(0, 4, 'Bob', 'Straight, Ten high'), 'seq': 41},
      ],
    });
    await tester.pump();
    final s = container.read(tableSessionProvider('t1'));
    expect(s.winners, {0, 4});
    expect(s.spotlight?.split, isTrue);
    expect(s.spotlight?.name, 'Alice & Bob');
    expect(s.spotlight?.seat, 0);
    expect(s.spotlight?.description, 'Straight, Ten high');
    expect(s.spotlight?.potIndex, 0);
    await finish(tester);
  });

  testWidgets('a pot run twice with a winner per board is not a split', (
    tester,
  ) async {
    container.read(tableSessionProvider('t1').notifier).start('tok');
    await tester.pump();
    transport.push('events', {
      'hand_number': 12,
      'events': [
        {...award(0, 0, 'Alice', 'Pair of Aces'), 'board': 1},
        {...award(0, 4, 'Bob', 'Flush'), 'seq': 41, 'board': 2},
      ],
    });
    await tester.pump();
    final s = container.read(tableSessionProvider('t1'));
    expect(s.winners, {0, 4});
    expect(s.spotlight?.split, isFalse);
    expect(s.spotlight?.name, 'Alice');
    await finish(tester);
  });

  testWidgets('pots are presented one at a time, side pot first', (
    tester,
  ) async {
    container.read(tableSessionProvider('t1').notifier).start('tok');
    await tester.pump();
    transport.push('events', {
      'hand_number': 12,
      'events': [
        award(0, 0, 'Alice', 'Pair of Aces'),
        award(1, 4, 'Bob', 'Flush'),
        {
          'seq': 50,
          'ts': 1,
          'kind': 'hand_ended',
          'results': {
            'pots': <Object>[],
            'seats': {
              '0': {
                'net': 60,
                'won': 100,
                'folded': false,
                'revealed': true,
                'best': ['As', 'Ah', 'Kd', '7c', '2d'],
              },
              '4': {
                'net': 150,
                'won': 200,
                'folded': false,
                'revealed': true,
                'best': ['Qh', 'Jh', 'Ah', '7h', '2h'],
              },
            },
          },
        },
      ],
    });
    await tester.pump();
    var s = container.read(tableSessionProvider('t1'));
    // First the side pot (silver): only Bob is a winner right now.
    expect(s.winnerPotIndex, 1);
    expect(s.winners, {4});
    expect(s.winnerLines, ['Bob|200|Flush']);
    expect(s.spotlight?.seat, 4);
    expect(s.spotlight?.potIndex, 1);
    expect(s.spotlight?.cards, ['Qh', 'Jh', 'Ah', '7h', '2h']);
    // The amount next to Bob is his net gain, not the pot.
    expect(s.winnerAmounts, {4: 150});
    // Then the main pot (gold), which stays.
    await tester.pump(potAwardStageDuration);
    s = container.read(tableSessionProvider('t1'));
    expect(s.winnerPotIndex, 0);
    expect(s.winners, {0});
    expect(s.winnerLines, ['Alice|100|Pair of Aces']);
    expect(s.winnerAmounts, {4: 150, 0: 60});
    expect(s.spotlight?.seat, 0);
    expect(s.spotlight?.potIndex, 0);
    await tester.pump(potAwardStageDuration * 2);
    s = container.read(tableSessionProvider('t1'));
    expect(s.winners, {0});
    // The next deal clears everything.
    transport.push('events', {
      'hand_number': 13,
      'events': [
        {'seq': 1, 'ts': 2, 'kind': 'hand_started'},
      ],
    });
    await tester.pump();
    s = container.read(tableSessionProvider('t1'));
    expect(s.winners, isEmpty);
    expect(s.winnerPotIndex, isNull);
    expect(s.spotlight, isNull);
    await finish(tester);
  });

  testWidgets('an all-in winner is shown its net gain, not the whole pot', (
    tester,
  ) async {
    container.read(tableSessionProvider('t1').notifier).start('tok');
    await tester.pump();
    // Alice was all in for 5000 against one caller: the pot is 10000, the
    // gain 5000.
    transport.push('events', {
      'hand_number': 12,
      'events': [
        {
          'seq': 40,
          'ts': 1,
          'kind': 'pot_awarded',
          'pot_index': 0,
          'seat': 0,
          'name': 'Alice',
          'amount': 10000,
          'description': 'Pair of Aces',
        },
        {
          'seq': 41,
          'ts': 1,
          'kind': 'hand_ended',
          'results': {
            'pots': <Object>[],
            'seats': {
              '0': {
                'net': 5000,
                'won': 10000,
                'folded': false,
                'revealed': true,
              },
              '4': {'net': -5000, 'won': 0, 'folded': false, 'revealed': true},
            },
          },
        },
      ],
    });
    await tester.pump();
    final s = container.read(tableSessionProvider('t1'));
    expect(s.winners, {0});
    expect(s.winnerLines, ['Alice|10000|Pair of Aces']);
    expect(s.winnerAmounts, {0: 5000});
    await finish(tester);
  });

  testWidgets('a single pot is one stage', (tester) async {
    container.read(tableSessionProvider('t1').notifier).start('tok');
    await tester.pump();
    transport.push('events', {
      'hand_number': 12,
      'events': [award(0, 0, 'Alice', 'Pair of Aces')],
    });
    await tester.pump();
    // Without the results in the batch the pot collected stands in.
    expect(container.read(tableSessionProvider('t1')).winnerAmounts, {0: 100});
    final s = container.read(tableSessionProvider('t1'));
    expect(s.winnerPotIndex, 0);
    expect(s.winners, {0});
    expect(s.winnerLines, ['Alice|100|Pair of Aces']);
    await finish(tester);
  });

  testWidgets('a chat line pops up next to the author for a moment', (
    tester,
  ) async {
    container.read(tableSessionProvider('t1').notifier).start('tok');
    await tester.pump();
    transport.push('chat', {
      'id': 7,
      'author_kind': 'player',
      'author_name': 'bob',
      'text': 'nice hand',
      'ts': 5,
    });
    await tester.pump();
    var s = container.read(tableSessionProvider('t1'));
    expect(s.chatBubbles[4], 'nice hand');
    expect(s.unreadChat, 1);
    // A spectator has no seat and no bubble.
    transport.push('chat', {
      'id': 8,
      'author_kind': 'spectator',
      'author_name': 'Watcher',
      'text': 'hi',
      'ts': 6,
    });
    await tester.pump();
    s = container.read(tableSessionProvider('t1'));
    expect(s.chatBubbles.length, 1);
    await tester.pump(chatBubbleDuration);
    s = container.read(tableSessionProvider('t1'));
    expect(s.chatBubbles, isEmpty);
    await finish(tester);
  });
}
