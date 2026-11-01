import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/join/join_page.dart';
import '../features/landing/landing_page.dart';
import '../features/table/play_page.dart';
import 'not_found_page.dart';

/// The router's own navigator.
///
/// Work that starts *above* the router needs a way back down to it: the
/// revoked return lands on whatever page the player left from, so it can
/// only run above the router, but a dialog is a route and
/// `Navigator.of(context)` only ever looks upwards. The key is the one
/// handle that points the other way. One per router, so two of them in a
/// test never share it.
final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(debugLabel: 'root navigator'),
);

/// Builds the application router. [initialLocation] is overridable for tests.
GoRouter createRouter({
  String initialLocation = '/',
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LandingPage()),
      GoRoute(
        path: '/t/:tableId',
        builder: (context, state) =>
            JoinPage(tableId: state.pathParameters['tableId']!),
        routes: [
          GoRoute(
            path: 'play',
            builder: (context, state) =>
                PlayPage(tableId: state.pathParameters['tableId']!),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
}

final routerProvider = Provider<GoRouter>(
  (ref) => createRouter(navigatorKey: ref.watch(rootNavigatorKeyProvider)),
);
