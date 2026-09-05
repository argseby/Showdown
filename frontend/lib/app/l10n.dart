import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

/// `null` means "follow the browser language".
class LocalePreferenceNotifier extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void set(Locale? locale) => state = locale;

  /// Cycles through the supported locales starting from [current].
  void next(Locale current) {
    const supported = AppLocalizations.supportedLocales;
    final index = supported.indexWhere(
      (l) => l.languageCode == current.languageCode,
    );
    state = supported[(index + 1) % supported.length];
  }
}

final localePreferenceProvider =
    NotifierProvider<LocalePreferenceNotifier, Locale?>(
      LocalePreferenceNotifier.new,
    );

/// shadcn_flutter ships English strings only. This delegate serves them for
/// every app locale so that a German UI does not fail to load the widget
/// library's own labels (date pickers, form validation, ...).
class ShadcnFallbackLocalizationsDelegate
    extends LocalizationsDelegate<ShadcnLocalizations> {
  const ShadcnFallbackLocalizationsDelegate();

  static const Locale _fallback = Locale('en');

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<ShadcnLocalizations> load(Locale locale) {
    const delegate = ShadcnLocalizations.delegate;
    return delegate.load(delegate.isSupported(locale) ? locale : _fallback);
  }

  @override
  bool shouldReload(ShadcnFallbackLocalizationsDelegate old) => false;
}

/// Extension for concise access in widgets.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
