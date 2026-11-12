import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/core/account.dart';
import 'package:showdown/core/providers.dart';
import 'package:showdown/core/rest_client.dart';
import 'package:showdown/features/account/now_playing_dialog.dart';

import 'test_helpers.dart';

class _MemoryTokens extends AccountTokenStore {
  _MemoryTokens([this.token]);
  String? token;
  @override
  Future<String?> load() async => token;
  @override
  Future<void> save(String t) async => token = t;
  @override
  Future<void> clear() async => token = null;
}

/// A server that offers the table link. [connected] says whether this
/// profile has already connected their vault; [deleted] records the call
/// that ends it.
MockClient api({
  required bool connected,
  bool nowPlayingOn = true,
  List<String>? calls,
}) {
  var live = connected;
  return MockClient((req) async {
    final path = req.url.path;
    calls?.add('${req.method} $path');
    switch ('${req.method} $path') {
      case 'GET /api/config':
        return http.Response(
          jsonEncode({
            'accounts': true,
            'revoked_sign_in': true,
            'revoked_now_playing': nowPlayingOn,
          }),
          200,
        );
      case 'GET /api/accounts/me':
        return http.Response(
          jsonEncode({
            'account': {'id': 'a1', 'handle': 'robin', 'display_name': 'Robin'},
          }),
          200,
        );
      case 'GET /api/accounts/me/now-playing':
        return http.Response(
          jsonEncode(
            live
                ? {
                    'connected': true,
                    'server': 'https://revoked.example',
                    'url': 'https://revoked.example/s/slug1',
                    'playing': 'Freitagsrunde · 50/100 · 4/6 seats',
                    'published': 'Freitagsrunde · 50/100 · 4/6 seats',
                    'trouble': '',
                  }
                : {'connected': false, 'playing': 'Not at a table'},
          ),
          200,
        );
      case 'DELETE /api/accounts/me/now-playing':
        live = false;
        return http.Response('', 204);
      case 'POST /api/accounts/revoked/connect/start':
        return http.Response(
          jsonEncode({
            'app_link': 'revoked://connect?state=s1',
            'wait': 'w1',
            'server': 'https://revoked.example',
            'check_code': '83C-047',
          }),
          200,
        );
    }
    return http.Response('{}', 404);
  });
}

List<Override> overrides(MockClient client, AccountTokenStore tokens) => [
  restClientProvider.overrideWithValue(
    RestClient(baseUrl: 'http://test', client: client),
  ),
  accountTokenStoreProvider.overrideWithValue(tokens),
];

void main() {
  test('an instance that does not offer it reports nothing', () async {
    final c = ProviderContainer(
      overrides: overrides(
        api(connected: false, nowPlayingOn: false),
        _MemoryTokens('tok'),
      ),
    );
    addTearDown(c.dispose);
    expect(await c.read(nowPlayingProvider.future), isNull);
  });

  test('a connected vault reports its link and what it says', () async {
    final c = ProviderContainer(
      overrides: overrides(api(connected: true), _MemoryTokens('tok')),
    );
    addTearDown(c.dispose);
    final state = await c.read(nowPlayingProvider.future);
    expect(state?.connected, isTrue);
    expect(state?.url, 'https://revoked.example/s/slug1');
    expect(state?.playing, contains('Freitagsrunde'));
  });

  testWidgets('without a connection the dialog offers to make one', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const NowPlayingDialog(),
        overrides: overrides(api(connected: false), _MemoryTokens('tok')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('now-playing-connect')), findsOneWidget);
    expect(find.byKey(const Key('now-playing-url')), findsNothing);
  });

  testWidgets('with one it shows the link, and turning it off is confirmed', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      wrap(
        const NowPlayingDialog(),
        overrides: overrides(
          api(connected: true, calls: calls),
          _MemoryTokens('tok'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('https://revoked.example/s/slug1'),
      findsOneWidget,
      reason: 'the player needs to see the link to paste it',
    );
    expect(find.textContaining('Freitagsrunde'), findsOneWidget);

    // The first tap asks; only the second ends it. Revoking a link is not
    // something to do on a mis-tap.
    await tester.tap(find.byKey(const Key('now-playing-off')));
    await tester.pumpAndSettle();
    expect(
      calls.contains('DELETE /api/accounts/me/now-playing'),
      isFalse,
      reason: 'the first tap only asks',
    );
    expect(find.textContaining('stays in your vault'), findsOneWidget);

    await tester.tap(find.byKey(const Key('now-playing-off')));
    await tester.pumpAndSettle();
    expect(calls, contains('DELETE /api/accounts/me/now-playing'));
    expect(find.byKey(const Key('now-playing-connect')), findsOneWidget);
  });
}
