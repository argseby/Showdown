import 'dart:convert';
import 'dart:io';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/app/app.dart';
import 'package:showdown/app/l10n.dart';
import 'package:showdown/app/router.dart';
import 'package:showdown/app/scroll_behavior.dart';
import 'package:showdown/app/theme.dart';
import 'package:showdown/protocol/protocol.dart';

/// Loads the snapshot fixture (Alice at seat 0, to act, with options).
Snapshot fixtureSnapshot() {
  final env = jsonDecode(
    File('../docs/protocol/fixtures/snapshot.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return Snapshot.fromJson(env['payload'] as Map<String, dynamic>);
}

/// Wraps a widget with the app's theme and localizations.
Widget wrap(
  Widget child, {
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: overrides,
    child: ShadcnApp(
      scrollBehavior: const NoScrollbarBehavior(),
      theme: darkTheme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ShadcnFallbackLocalizationsDelegate(),
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Mirrors ShowdownApp: a drawer layer above everything, so an
      // adaptive popover has somewhere to go on a phone.
      builder: (context, child) =>
          DrawerOverlay(child: child ?? const SizedBox.shrink()),
      home: Scaffold(child: child),
    ),
  );
}

/// Wraps a routed app so that pages may navigate; [routes] are go_router
/// routes, [initialLocation] the start.
Widget wrapRouter({
  required List<RouteBase> routes,
  required String initialLocation,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: ShadcnApp.router(
      routerConfig: GoRouter(routes: routes, initialLocation: initialLocation),
      scrollBehavior: const NoScrollbarBehavior(),
      // Mirrors ShowdownApp: a drawer layer above the router, so a select
      // inside a dialog route can open on a phone.
      builder: (context, child) =>
          DrawerOverlay(child: child ?? const SizedBox.shrink()),
      theme: darkTheme,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ShadcnFallbackLocalizationsDelegate(),
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// The real application, with the router pointed where a test wants it.
/// Goes through [routerProvider] so the root navigator key is wired exactly
/// as it is in production - a dialog opened from above the router depends
/// on it.
Widget app({
  String initialLocation = '/',
  List<Override> overrides = const [],
}) {
  // A router per call, as the tests that pump several in a row expect,
  // and the key it is built with handed to the provider beside it.
  final navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root navigator');
  return ProviderScope(
    overrides: [
      rootNavigatorKeyProvider.overrideWithValue(navigatorKey),
      routerProvider.overrideWithValue(
        createRouter(
          initialLocation: initialLocation,
          navigatorKey: navigatorKey,
        ),
      ),
      ...overrides,
    ],
    child: const ShowdownApp(),
  );
}
