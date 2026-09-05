import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double _radius = 0.5;

/// Light variant of the zinc palette.
const ThemeData lightTheme = ThemeData(
  colorScheme: ColorSchemes.lightZinc,
  radius: _radius,
);

/// Default dark zinc palette.
const ThemeData darkTheme = ThemeData.dark(
  colorScheme: ColorSchemes.darkZinc,
  radius: _radius,
);

/// Follows the system by default; the top bar toggle switches explicitly
/// and the choice is remembered across reloads.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'pref:theme';

  @override
  ThemeMode build() {
    SharedPreferences.getInstance().then((p) {
      switch (p.getString(_key)) {
        case 'light':
          state = ThemeMode.light;
        case 'dark':
          state = ThemeMode.dark;
      }
    }).ignore();
    return ThemeMode.system;
  }

  void set(ThemeMode mode) {
    state = mode;
    SharedPreferences.getInstance()
        .then((p) => p.setString(_key, mode.name))
        .ignore();
  }

  /// Flips to the opposite of what is currently rendered.
  void toggle(Brightness current) {
    set(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
