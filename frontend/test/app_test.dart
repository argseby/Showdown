import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showdown/app/app.dart';
import 'package:showdown/app/l10n.dart';
import 'package:showdown/app/router.dart';
import 'package:showdown/core/providers.dart';
import 'package:showdown/core/rest_client.dart';
import 'package:showdown/features/landing/landing_page.dart';

Widget app({
  String initialLocation = '/',
  Locale? locale,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      routerProvider.overrideWithValue(
        createRouter(initialLocation: initialLocation),
      ),
      if (locale != null)
        localePreferenceProvider.overrideWith(() => _FixedLocale(locale)),
      ...overrides,
    ],
    child: const ShowdownApp(),
  );
}

class _FixedLocale extends LocalePreferenceNotifier {
  _FixedLocale(this.locale);
  final Locale locale;
  @override
  Locale? build() => locale;
}

void main() {
  testWidgets('landing page renders and validates the table code', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Texas Hold\'em for your private group.'), findsOneWidget);
    expect(find.byKey(const Key('landing-error')), findsNothing);

    await tester.enterText(find.byKey(const Key('landing-code')), 'nope');
    await tester.tap(find.byKey(const Key('landing-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('landing-error')), findsOneWidget);
  });

  testWidgets('unknown routes show the 404 page', (tester) async {
    await tester.pumpWidget(app(initialLocation: '/does/not/exist'));
    await tester.pumpAndSettle();
    expect(find.text('Page not found'), findsOneWidget);
  });

  testWidgets('the former admin and leaderboard routes are gone', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final rest = RestClient(
      baseUrl: 'http://test',
      client: MockClient((req) async => http.Response('{}', 404)),
    );
    for (final path in ['/admin', '/leaderboard', '/admin/tables/x']) {
      await tester.pumpWidget(
        app(
          initialLocation: path,
          overrides: [restClientProvider.overrideWithValue(rest)],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Page not found'), findsOneWidget, reason: path);
    }
    await tester.pumpWidget(
      app(overrides: [restClientProvider.overrideWithValue(rest)]),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LandingPage), findsOneWidget);
    expect(find.byKey(const Key('landing-create')), findsOneWidget);
  });

  testWidgets('German locale is complete for the landing page', (tester) async {
    await tester.pumpWidget(app(locale: const Locale('de')));
    await tester.pumpAndSettle();
    expect(
      find.text('Texas Hold\'em für deine private Runde.'),
      findsOneWidget,
    );
  });
}
