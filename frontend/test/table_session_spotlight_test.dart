import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/core/ws_transport.dart';
import 'package:showdown/features/table/table_session.dart';

import 'test_helpers.dart';

/// Transport that answers the hello with a welcome and lets the test push
/// server messages.
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
    container.dispose();
  });

  test(
    'the winner spotlight takes the best five of the finished board',
    () async {
      container.read(tableSessionProvider('t1').notifier).start('tok');
      await Future<void>.delayed(Duration.zero);
      // Everyone was all-in on the flop: Bob's hand is revealed and described
      // on the three-card board.
      transport.push('events', {
        'hand_number': 12,
        'events': [
          {
            'seq': 7,
            'ts': 1,
            'kind': 'hands_revealed',
            'reveals': [
              {
                'seat': 4,
                'cards': ['Qs', 'Qd'],
                'description': 'Pair of Queens',
                'best': ['Qs', 'Qd', 'Ah', '7c', '2d'],
              },
            ],
          },
        ],
      });
      await Future<void>.delayed(Duration.zero);
      var state = container.read(tableSessionProvider('t1'));
      expect(state.spotlight?.description, 'Pair of Queens');
      expect(state.spotlight?.cards, ['Qs', 'Qd', 'Ah', '7c', '2d']);
      // The river completed a set; the pot award arrives in the same batch as
      // the final results, which carry the best five of the full board.
      transport.push('events', {
        'hand_number': 12,
        'events': [
          {
            'seq': 12,
            'ts': 2,
            'kind': 'pot_awarded',
            'seat': 4,
            'name': 'Bob',
            'pot_index': 0,
            'amount': 900,
            'description': 'Three of a Kind, Queens',
          },
          {
            'seq': 13,
            'ts': 2,
            'kind': 'hand_ended',
            'results': {
              'pots': <Object>[],
              'seats': {
                '4': {
                  'net': 450,
                  'won': 900,
                  'folded': false,
                  'revealed': true,
                  'cards': ['Qs', 'Qd'],
                  'description': 'Three of a Kind, Queens',
                  'best': ['Qs', 'Qd', 'Qh', 'Ah', '7c'],
                },
              },
            },
          },
        ],
      });
      await Future<void>.delayed(Duration.zero);
      state = container.read(tableSessionProvider('t1'));
      expect(state.spotlight?.winner, isTrue);
      expect(state.spotlight?.description, 'Three of a Kind, Queens');
      expect(state.spotlight?.cards, ['Qs', 'Qd', 'Qh', 'Ah', '7c']);
      expect(state.best[4], ['Qs', 'Qd', 'Qh', 'Ah', '7c']);
    },
  );
}
