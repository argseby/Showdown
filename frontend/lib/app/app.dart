import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../features/friends/notifications_overlay.dart';
import 'l10n.dart';
import 'router.dart';
import 'scroll_behavior.dart';
import 'theme.dart';

class ShowdownApp extends ConsumerWidget {
  const ShowdownApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localePreferenceProvider);
    final router = ref.watch(routerProvider);

    return ShadcnApp.router(
      routerConfig: router,
      // No platform scrollbar: every surface here draws its own edge.
      scrollBehavior: const NoScrollbarBehavior(),
      // A popover turns itself into a drawer on a phone, and a drawer needs
      // a [DrawerOverlay] to live in. Scaffold carries one, but a dialog
      // route is a sibling of the page rather than a child of it, so a
      // select inside one found none and opened nothing. One here sits
      // above the router, so every route and every dialog has a layer.
      //
      // Friend requests and invitations are about the person, so they
      // ride above whatever page they happen to be on.
      builder: (context, child) => DrawerOverlay(
        child: NotificationsScope(child: child ?? const SizedBox.shrink()),
      ),
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ShadcnFallbackLocalizationsDelegate(),
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
    );
  }
}
