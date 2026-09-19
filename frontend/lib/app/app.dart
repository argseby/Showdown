import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../features/friends/notifications_overlay.dart';
import 'l10n.dart';
import 'router.dart';
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
      // Friend requests and invitations are about the person, so they
      // ride above whatever page they happen to be on.
      builder: (context, child) =>
          NotificationsScope(child: child ?? const SizedBox.shrink()),
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
