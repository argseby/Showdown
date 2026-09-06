import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/core/providers.dart';
import 'package:showdown/core/rest_client.dart';
import 'package:showdown/features/table/replay/replay_dialog.dart';

import 'test_helpers.dart';

Map<String, Object?> _hand(int number) => {
  'id': number,
  'number': number,
  'started_at': 1789000000000 + number,
  'ended_at': 1789000001000 + number,
  'button_seat': 3,
  'small_blind': 50,
  'big_blind': 100,
  'ante': 0,
  'stacks_at_start': {'0': 10000, '4': 10000},
  'events': [
    {
      'seq': 1,
      'ts': 1,
      'kind': 'hand_started',
      'button_seat': 3,
      'sb_seat': 4,
      'bb_seat': 0,
      'blinds': {'small': 50, 'big': 100},
      'ante': 0,
      'stacks': {'0': 10000, '4': 10000},
    },
  ],
  'voided': false,
};

void main() {
  testWidgets('the replay steps to the previous and next hand', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final rest = RestClient(
      baseUrl: 'http://test',
      client: MockClient((req) async {
        if (req.url.path == '/api/tables/k7m2p9xq4w/hands') {
          return http.Response(
            jsonEncode({
              'hands': [_hand(12), _hand(11), _hand(10)],
            }),
            200,
          );
        }
        return http.Response('{"error":{"code":"not_found"}}', 404);
      }),
    );
    await tester.pumpWidget(
      wrap(
        ReplayDialog(
          tableId: 'k7m2p9xq4w',
          token: 'tok',
          admin: false,
          base: fixtureSnapshot(),
          viewerSeat: 0,
        ),
        overrides: [restClientProvider.overrideWithValue(rest)],
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('replay-hand-12')));
    await tester.pump();
    expect(find.textContaining('Hand #12'), findsWidgets);
    // Newest hand: nothing after it, hand 11 before it.
    expect(
      tester
          .widget<GhostButton>(find.byKey(const Key('replay-next-hand')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('replay-prev-hand')));
    await tester.pump();
    expect(find.textContaining('Hand #11'), findsWidgets);
    expect(
      tester
          .widget<GhostButton>(find.byKey(const Key('replay-next-hand')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('replay-prev-hand')));
    await tester.pump();
    expect(find.textContaining('Hand #10'), findsWidgets);
    expect(
      tester
          .widget<GhostButton>(find.byKey(const Key('replay-prev-hand')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('replay-next-hand')));
    await tester.pump();
    expect(find.textContaining('Hand #11'), findsWidgets);
  });
}
