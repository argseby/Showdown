import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showdown/core/account.dart';
import 'package:showdown/core/providers.dart';
import 'package:showdown/core/rest_client.dart';
import 'package:showdown/core/revoked_browser.dart';
import 'package:showdown/features/account/account_dialog.dart';

import 'test_helpers.dart';

const _appLink =
    'revoked://signin?client_id=https%3A%2F%2Fpoker.example&revoked_return=background';

class _MemoryTokens extends AccountTokenStore {
  String? token;

  @override
  Future<String?> load() async => token;

  @override
  Future<void> save(String t) async => token = t;

  @override
  Future<void> clear() async => token = null;
}

class _FakeBrowser implements RevokedBrowser {
  _FakeBrowser([this._error]);

  String? _error;
  final opened = <String>[];

  @override
  void go(String url) => opened.add(url);

  @override
  String? take() {
    final error = _error;
    _error = null;
    return error;
  }
}

/// A server whose sign-in stays unanswered until [answer] is set.
class _Server {
  _Server({this.linked = false});

  final bool linked;
  Map<String, dynamic>? answer;
  int asked = 0;
  final seen = <String>[];
  final started = <String>[];

  late final rest = RestClient(
    baseUrl: 'http://test',
    client: MockClient((req) async {
      seen.add(req.url.path);
      switch (req.url.path) {
        case '/api/config':
          return http.Response(
            '{"ice_servers":[],"accounts":true,"revoked_sign_in":true,'
            '"revoked_default_server":"https://api.revoked.link",'
            '"version":"v1.2.3"}',
            200,
          );
        case '/api/accounts/revoked/start':
          final issuer = (jsonDecode(req.body) as Map)['issuer'] as String;
          started.add(issuer);
          return http.Response(
            jsonEncode({
              'app_link': _appLink,
              'wait': 'page-key',
              // The server's normalized form of what was typed.
              'issuer': issuer.startsWith('http') ? issuer : 'https://$issuer',
              'check_code': '0D2-99B',
            }),
            200,
          );
        case '/api/accounts/revoked/wait':
          asked++;
          expect(jsonDecode(req.body), {'wait': 'page-key'});
          return http.Response(jsonEncode(answer ?? {'done': false}), 200);
        case '/api/accounts/revoked/finish':
          if (linked) {
            return http.Response(
              '{"token":"t","account":{"id":"a","handle":"robin",'
              '"display_name":"Robin","created_at":0}}',
              200,
            );
          }
          return http.Response(
            '{"pending":true,"claim":"claim-1",'
            '"issuer":"https://revoked.example","suggested_handle":"robin",'
            '"name":"Robin"}',
            200,
          );
      }
      return http.Response('{}', 404);
    }),
  );
}

Future<_FakeBrowser> _openPanel(
  WidgetTester tester,
  _Server server, {
  Size size = const Size(1280, 800),
}) async {
  final browser = await _openAccount(tester, server, size: size);
  await tester.ensureVisible(find.byKey(const Key('revoked-continue')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('revoked-continue')));
  await tester.pumpAndSettle();
  return browser;
}

Future<_FakeBrowser> _openAccount(
  WidgetTester tester,
  _Server server, {
  Size size = const Size(1280, 800),
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final browser = _FakeBrowser();
  await tester.pumpWidget(
    wrap(
      Builder(
        builder: (context) => PrimaryButton(
          key: const Key('open-account'),
          onPressed: () => showAccountDialog(context),
          child: const Text('Open'),
        ),
      ),
      overrides: [
        restClientProvider.overrideWithValue(server.rest),
        revokedBrowserProvider.overrideWithValue(browser),
        accountTokenStoreProvider.overrideWithValue(_MemoryTokens()),
      ],
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('open-account')));
  await tester.pumpAndSettle();
  return browser;
}

Future<void> _nextAsk(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the button shows a code to scan, and does not leave the page', (
    tester,
  ) async {
    final server = _Server();
    final browser = await _openPanel(tester, server);

    expect(
      tester.widget<QrImageView>(find.byType(QrImageView)).size,
      greaterThanOrEqualTo(200),
    );
    expect(find.byKey(const Key('revoked-qr')), findsOneWidget);
    expect(find.textContaining('0D2-99B'), findsOneWidget);
    expect(
      browser.opened,
      isEmpty,
      reason: 'with no app here a revoked:// link does nothing at all',
    );

    await tester.tap(find.byKey(const Key('revoked-open-here')));
    expect(browser.opened, [_appLink]);

    await tester.tap(find.byKey(const Key('revoked-wait-close')));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'it keeps asking until the answer comes, then asks for a handle',
    (tester) async {
      final server = _Server();
      await _openPanel(tester, server);

      await _nextAsk(tester);
      await _nextAsk(tester);
      expect(server.asked, 2);
      expect(find.byKey(const Key('revoked-qr')), findsOneWidget);

      server.answer = {'done': true, 'code': 'one-time', 'error': ''};
      await _nextAsk(tester);

      expect(find.byKey(const Key('revoked-qr')), findsNothing);
      expect(find.text('Pick your name'), findsOneWidget);
    },
  );

  testWidgets('a known identity is simply signed in', (tester) async {
    final server = _Server(linked: true);
    await _openPanel(tester, server);

    server.answer = {'done': true, 'code': 'one-time', 'error': ''};
    await _nextAsk(tester);

    expect(server.seen, contains('/api/accounts/revoked/finish'));
    expect(find.byKey(const Key('revoked-qr')), findsNothing);
    // The account dialog has done its job too.
    expect(find.byKey(const Key('revoked-continue')), findsNothing);
  });

  testWidgets('the sign-in starts with the default server, and says so', (
    tester,
  ) async {
    final server = _Server();
    await _openPanel(tester, server);

    expect(server.started, ['https://api.revoked.link']);
    await tester.tap(find.byKey(const Key('revoked-wait-close')));
    await tester.pumpAndSettle();
    expect(find.text('api.revoked.link'), findsOneWidget);
  });

  testWidgets('a player changes the server, and it is remembered', (
    tester,
  ) async {
    final server = _Server();
    await _openAccount(tester, server);

    await tester.tap(find.byKey(const Key('revoked-server-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('revoked-server')),
      'own.example',
    );
    await tester.tap(find.byKey(const Key('revoked-continue')));
    await tester.pumpAndSettle();
    expect(server.started, ['own.example']);

    await tester.tap(find.byKey(const Key('revoked-wait-close')));
    await tester.pumpAndSettle();
    expect(find.text('own.example'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pref:revoked_server'), 'https://own.example');

    // The next sign-in goes there, and the default stays one tap away.
    await tester.tap(find.byKey(const Key('revoked-continue')));
    await tester.pumpAndSettle();
    expect(server.started.last, 'https://own.example');
    await tester.tap(find.byKey(const Key('revoked-wait-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('revoked-server-edit')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('revoked-server-default')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('revoked-server-default')));
    await tester.pumpAndSettle();
    expect(find.text('api.revoked.link'), findsOneWidget);
  });

  testWidgets('an app on another server is told how to fix it', (tester) async {
    final server = _Server();
    await _openPanel(tester, server);

    server.answer = {'done': true, 'code': '', 'error': 'issuer_mismatch'};
    await _nextAsk(tester);

    expect(find.textContaining('different server'), findsOneWidget);
  });

  testWidgets('a decline on the phone reaches the page', (tester) async {
    final server = _Server();
    await _openPanel(tester, server);

    server.answer = {'done': true, 'code': '', 'error': 'access_denied'};
    await _nextAsk(tester);

    expect(find.byKey(const Key('revoked-qr')), findsNothing);
    expect(find.text('The sign-in was declined.'), findsOneWidget);
    expect(server.seen, isNot(contains('/api/accounts/revoked/finish')));
  });

  testWidgets('closing the panel stops asking', (tester) async {
    final server = _Server();
    await _openPanel(tester, server);

    await tester.tap(find.byKey(const Key('revoked-wait-close')));
    await tester.pumpAndSettle();
    final asked = server.asked;
    await _nextAsk(tester);

    expect(server.asked, asked);
    expect(find.byKey(const Key('revoked-error')), findsNothing);
  });

  testWidgets('a phone leads with opening the app', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final server = _Server();
    await _openPanel(tester, server, size: const Size(375, 812));

    final open = tester.getTopLeft(find.byKey(const Key('revoked-open-here')));
    final qr = tester.getTopLeft(find.byKey(const Key('revoked-qr')));
    expect(open.dy, lessThan(qr.dy));

    await tester.tap(find.byKey(const Key('revoked-wait-close')));
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;
  });

  for (final size in const [
    Size(320, 640),
    Size(375, 812),
    Size(812, 375),
    Size(768, 1024),
    Size(1280, 800),
  ]) {
    testWidgets('the panel fits at ${size.width}x${size.height}', (
      tester,
    ) async {
      final server = _Server();
      await _openPanel(tester, server, size: size);

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const Key('revoked-open-here')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('revoked-wait-close')).hitTestable(),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('revoked-wait-close')));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('a failure that came back through the address is explained', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final server = _Server();
    await tester.pumpWidget(
      app(
        overrides: [
          restClientProvider.overrideWithValue(server.rest),
          revokedBrowserProvider.overrideWithValue(
            _FakeBrowser('access_denied'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('The sign-in was declined.'), findsOneWidget);

    // Let the toast time itself out; otherwise its timer outlives the test.
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();
  });

  testWidgets('an ordinary visit does not touch the sign-in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final server = _Server();
    await tester.pumpWidget(
      app(
        overrides: [
          restClientProvider.overrideWithValue(server.rest),
          revokedBrowserProvider.overrideWithValue(_FakeBrowser()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(server.seen.where((s) => s.contains('/revoked/')), isEmpty);
  });
}
