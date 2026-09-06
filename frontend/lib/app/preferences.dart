import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sound cue on your turn. On by default (owner decision); the toggle in the
/// top bar and the M shortcut switch it off.
class SoundEnabledNotifier extends Notifier<bool> {
  static const _key = 'pref:sound';

  @override
  bool build() {
    SharedPreferences.getInstance().then((p) {
      final v = p.getBool(_key);
      if (v != null) state = v;
    }).ignore();
    return true;
  }

  void toggle() => set(!state);

  void set(bool value) {
    state = value;
    SharedPreferences.getInstance()
        .then((p) => p.setBool(_key, value))
        .ignore();
  }
}

final soundEnabledProvider = NotifierProvider<SoundEnabledNotifier, bool>(
  SoundEnabledNotifier.new,
);

/// Four-color deck preference (toggle arrives with M5 polish).
class FourColorDeckNotifier extends Notifier<bool> {
  static const _key = 'pref:four_color';

  @override
  bool build() {
    SharedPreferences.getInstance().then((p) {
      final v = p.getBool(_key);
      if (v != null) state = v;
    }).ignore();
    return false;
  }

  void set(bool value) {
    state = value;
    SharedPreferences.getInstance()
        .then((p) => p.setBool(_key, value))
        .ignore();
  }
}

final fourColorDeckProvider = NotifierProvider<FourColorDeckNotifier, bool>(
  FourColorDeckNotifier.new,
);

/// How chip amounts are shown: as coins or as big blinds ("3 BB").
enum ChipDisplay { coins, bigBlinds }

class ChipDisplayNotifier extends Notifier<ChipDisplay> {
  static const _key = 'pref:chip_display';

  @override
  ChipDisplay build() {
    SharedPreferences.getInstance().then((p) {
      final v = p.getString(_key);
      if (v == 'bb') state = ChipDisplay.bigBlinds;
    }).ignore();
    return ChipDisplay.coins;
  }

  void toggle() => set(
    state == ChipDisplay.coins ? ChipDisplay.bigBlinds : ChipDisplay.coins,
  );

  void set(ChipDisplay value) {
    state = value;
    SharedPreferences.getInstance()
        .then(
          (p) => p.setString(
            _key,
            value == ChipDisplay.bigBlinds ? 'bb' : 'coins',
          ),
        )
        .ignore();
  }
}

final chipDisplayProvider = NotifierProvider<ChipDisplayNotifier, ChipDisplay>(
  ChipDisplayNotifier.new,
);

/// Display size for the table: cards, chips, buttons and text scale
/// together (accessibility). 1.0 = normal, 1.25 = large, 1.5 = extra large.
/// Turn notifications while the tab is in the background (default off; the
/// browser asks for permission when switched on).
class NotifyTurnNotifier extends Notifier<bool> {
  static const _key = 'pref:notify_turn';

  @override
  bool build() {
    SharedPreferences.getInstance().then((p) {
      final v = p.getBool(_key);
      if (v != null) state = v;
    }).ignore();
    return false;
  }

  void set(bool value) {
    state = value;
    SharedPreferences.getInstance()
        .then((p) => p.setBool(_key, value))
        .ignore();
  }
}

final notifyTurnProvider = NotifierProvider<NotifyTurnNotifier, bool>(
  NotifyTurnNotifier.new,
);

/// Receive the other players' video (off saves bandwidth; own camera
/// unaffected).
class ShowCamerasNotifier extends Notifier<bool> {
  static const _key = 'pref:show_cameras';

  @override
  bool build() {
    SharedPreferences.getInstance().then((p) {
      final v = p.getBool(_key);
      if (v != null) state = v;
    }).ignore();
    return true;
  }

  void set(bool value) {
    state = value;
    SharedPreferences.getInstance()
        .then((p) => p.setBool(_key, value))
        .ignore();
  }
}

final showCamerasProvider = NotifierProvider<ShowCamerasNotifier, bool>(
  ShowCamerasNotifier.new,
);

class UiScaleNotifier extends Notifier<double> {
  static const _key = 'pref:ui_scale';
  static const options = [1.0, 1.25, 1.5];

  @override
  double build() {
    SharedPreferences.getInstance().then((p) {
      final v = p.getDouble(_key);
      if (v != null && options.contains(v)) state = v;
    }).ignore();
    return 1.0;
  }

  void set(double value) {
    state = value;
    SharedPreferences.getInstance()
        .then((p) => p.setDouble(_key, value))
        .ignore();
  }
}

final uiScaleProvider = NotifierProvider<UiScaleNotifier, double>(
  UiScaleNotifier.new,
);
