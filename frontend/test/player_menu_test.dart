import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/core/providers.dart';
import 'package:showdown/core/rest_client.dart';
import 'package:showdown/features/admin/admin_player_actions.dart';
import 'package:showdown/features/admin/admin_widgets.dart';
import 'package:showdown/features/table/widgets/player_menu.dart';
import 'package:showdown/protocol/protocol.dart';

import 'test_helpers.dart';

PlayerView bob({
  String voice = 'on',
  bool camera = true,
  bool muted = false,
  bool? bot,
}) => PlayerView(
  id: 'p4',
  name: 'Bob',
  avatar: 0,
  bot: bot,
  voice: voice,
  camera: camera,
  muted: muted,
  stack: 100,
  status: 'active',
  connected: true,
  inHand: false,
  folded: false,
  allIn: false,
  betThisStreet: 0,
  totalBet: 0,
  lastAction: null,
);

void main() {
  Future<List<String>> openMenu(WidgetTester tester, PlayerView player) async {
    adminToastsEnabled = false;
    addTearDown(() => adminToastsEnabled = true);
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final calls = <String>[];
    final rest = RestClient(
      baseUrl: 'http://test',
      client: MockClient((req) async {
        calls.add('${req.method} ${req.url.path}');
        return http.Response('{}', 200);
      }),
    );
    await tester.pumpWidget(
      wrap(
        Consumer(
          builder: (context, ref, _) => PrimaryButton(
            key: const Key('open'),
            onPressed: () => showPlayerMenu(
              context,
              tableId: 't1',
              player: player,
              admin: AdminPlayerActions(
                ref: ref,
                context: context,
                tableId: 't1',
                token: 'adm',
              ),
            ),
            child: const Text('open'),
          ),
        ),
        overrides: [restClientProvider.overrideWithValue(rest)],
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pump(const Duration(milliseconds: 400));
    return calls;
  }

  testWidgets('the host switches mute the microphone and camera, off only', (
    tester,
  ) async {
    final calls = await openMenu(tester, bob());
    expect(find.text('FOR EVERYONE (HOST)'), findsOneWidget);
    expect(find.byKey(const Key('host-mute-all')), findsOneWidget);
    final mic = tester.widget<Switch>(find.byKey(const Key('host-mic')));
    expect(mic.value, isTrue);
    expect(mic.onChanged, isNotNull);
    await tester.tap(find.byKey(const Key('host-mic')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(calls, contains('POST /api/admin/tables/t1/players/p4/voice-mute'));
    await tester.tap(find.byKey(const Key('host-camera')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(calls, contains('POST /api/admin/tables/t1/players/p4/camera-off'));
    await tester.tap(find.byKey(const Key('host-mute-all')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(calls, contains('POST /api/admin/tables/t1/players/p4/mute'));
  });

  testWidgets('a muted microphone cannot be switched on by the host', (
    tester,
  ) async {
    await openMenu(tester, bob(voice: 'muted', camera: false));
    final mic = tester.widget<Switch>(find.byKey(const Key('host-mic')));
    expect(mic.value, isFalse);
    expect(mic.onChanged, isNull);
    final cam = tester.widget<Switch>(find.byKey(const Key('host-camera')));
    expect(cam.value, isFalse);
    expect(cam.onChanged, isNull);
  });

  testWidgets('the menu of a bot says who is playing the seat', (tester) async {
    await openMenu(tester, bob());
    expect(find.byKey(const Key('player-bot')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await openMenu(tester, bob(bot: true));
    expect(find.byKey(const Key('player-bot')), findsOneWidget);
  });
}
