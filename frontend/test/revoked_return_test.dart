import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showdown/core/providers.dart';
import 'package:showdown/core/rest_client.dart';
import 'package:showdown/core/revoked_browser.dart';

import 'test_helpers.dart';

/// Stands in for the address bar the player comes back to: hands the
/// one-time parameters over once, as the real one does after stripping
/// them, and is empty from then on.
class _FakeBrowser implements RevokedBrowser {
  _FakeBrowser(this._ret);

  RevokedReturn _ret;
  final opened = <String>[];

  @override
  void go(String url) => opened.add(url);

  @override
  RevokedReturn take() {
    final ret = _ret;
    _ret = (code: null, error: null);
    return ret;
  }
}

RestClient _rest({List<String>? seen, bool linked = false}) => RestClient(
  baseUrl: 'http://test',
  client: MockClient((req) async {
    seen?.add('${req.method} ${req.url.path}');
    if (req.url.path == '/api/config') {
      return http.Response(
        '{"ice_servers":[],"accounts":true,"revoked_sign_in":true,'
        '"version":"v1.2.3"}',
        200,
      );
    }
    if (req.url.path == '/api/accounts/revoked/finish') {
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

void main() {
  testWidgets('a new identity is asked for a handle', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      app(
        overrides: [
          restClientProvider.overrideWithValue(_rest()),
          revokedBrowserProvider.overrideWithValue(
            _FakeBrowser((code: 'one-time', error: null)),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // The dialog is a route, and the scope that opens it sits above the
    // router: without the router's own navigator this threw and the
    // player was left with a spent code and the catch-all message.
    expect(find.text('Pick your name'), findsOneWidget);
    expect(
      find.text('That sign-in did not finish. Please try again.'),
      findsNothing,
    );
  });

  testWidgets('the handle dialog opens on whatever page the player left from', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    // The return lands wherever the sign-in started, not only on the
    // landing page, and the navigator it needs belongs to that route.
    await tester.pumpWidget(
      app(
        initialLocation: '/t/k7m2p9xq4w',
        overrides: [
          restClientProvider.overrideWithValue(_rest()),
          revokedBrowserProvider.overrideWithValue(
            _FakeBrowser((code: 'one-time', error: null)),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pick your name'), findsOneWidget);
  });

  testWidgets('a declined sign-in says so rather than failing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      app(
        overrides: [
          restClientProvider.overrideWithValue(_rest()),
          revokedBrowserProvider.overrideWithValue(
            _FakeBrowser((code: null, error: 'access_denied')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('The sign-in was declined.'), findsOneWidget);
    expect(find.text('Pick your name'), findsNothing);

    // Let the toast time itself out; otherwise its timer outlives the test.
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();
  });

  testWidgets('an address with nothing in it costs no request', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final seen = <String>[];
    await tester.pumpWidget(
      app(
        overrides: [
          restClientProvider.overrideWithValue(_rest(seen: seen)),
          revokedBrowserProvider.overrideWithValue(
            _FakeBrowser((code: null, error: null)),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      seen.where((s) => s.contains('/revoked/')),
      isEmpty,
      reason: 'an ordinary visit must not touch the sign-in',
    );
  });
}
