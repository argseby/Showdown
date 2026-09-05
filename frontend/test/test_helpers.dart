import 'dart:convert';
import 'dart:io';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/app/l10n.dart';
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
