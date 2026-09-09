import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/core/ws_transport.dart';
import 'package:showdown/features/table/table_session.dart';
import 'package:showdown/protocol/protocol.dart';

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

  /// The fixture with every bet collected into a bigger pot.
  Snapshot collected(Snapshot s, {int? handNumber}) => s.copyWith(
    table: handNumber == null
        ? s.table
        : s.table.copyWith(handNumber: handNumber),
    seats: [
      for (final sv in s.seats)
        sv.player == null
            ? sv
            : sv.copyWith(player: sv.player!.copyWith(betThisStreet: 0)),
    ],
    hand: s.hand!.copyWith(
      pots: const [
        PotView(amount: 600, eligibleSeats: [0, 3, 4]),
      ],
    ),
  );

  testWidgets('bets that left the felt fly to the pot, then the pot updates', (
    tester,
  ) async {
    container.read(tableSessionProvider('t1').notifier).start('tok');
    await tester.pump();
    final s = fixtureSnapshot();
    transport.push('snapshot', collected(s).toJson());
    await tester.pump();
    var state = container.read(tableSessionProvider('t1'));
    // Bob (seat 4) had 300 on the felt; the pots still read 300 for now.
    expect(state.collecting, {4: 300});
    expect(state.collectingPots?.single.amount, 300);
    expect(state.collectId, 1);
    expect(state.snapshot?.hand?.pots.single.amount, 600);

    await tester.pump(chipCollectDuration + const Duration(milliseconds: 10));
    state = container.read(tableSessionProvider('t1'));
    expect(state.collecting, isEmpty);
    expect(state.collectingPots, isNull);
    expect(state.collectId, 1);

    // The same drop across a hand boundary is a new deal, not a collection.
    transport.push('snapshot', s.toJson());
    await tester.pump();
    transport.push('snapshot', collected(s, handNumber: 13).toJson());
    await tester.pump();
    state = container.read(tableSessionProvider('t1'));
    expect(state.collecting, isEmpty);
    expect(state.collectId, 1);

    container.dispose();
    await tester.pump();
  });
}
