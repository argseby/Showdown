import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/join/join_page.dart';
import '../features/landing/landing_page.dart';
import '../features/table/play_page.dart';
import 'not_found_page.dart';

/// Builds the application router. [initialLocation] is overridable for tests.
GoRouter createRouter({String initialLocation = '/'}) {
  return GoRouter(
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

final routerProvider = Provider<GoRouter>((ref) => createRouter());
