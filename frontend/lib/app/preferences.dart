import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/providers.dart';

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

/// Whether bets, pots and stacks are drawn as chip stacks (on by default);
/// off shows the amounts as numbers only.
class ChipStacksNotifier extends Notifier<bool> {
  static const _key = 'pref:chip_stacks';

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

final chipStacksProvider = NotifierProvider<ChipStacksNotifier, bool>(
  ChipStacksNotifier.new,
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

/// Whether the hats of the other players are drawn (default on); the own
/// hat is always shown.
class ShowHatsNotifier extends Notifier<bool> {
  static const _key = 'pref:show_hats';

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

final showHatsProvider = NotifierProvider<ShowHatsNotifier, bool>(
  ShowHatsNotifier.new,
);

/// Fixed seats (the default): every seat has its place on the oval, seat
/// 0 at the bottom, so the table looks the same for everyone and "seat 8"
/// means the same spot on every screen. Off: the viewer is rotated to the
/// bottom and only the taken seats are spread around the oval.
class FixedSeatsNotifier extends Notifier<bool> {
  static const _key = 'pref:fixed_seats';

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

final fixedSeatsProvider = NotifierProvider<FixedSeatsNotifier, bool>(
  FixedSeatsNotifier.new,
);

/// Controller hints on screen (the legend strip under the action bar and
/// the button caps) while a pad is connected. Off by default: the help
/// overlay (Start) has the full reference, and a pad that stays plugged
/// in must not clutter the table for good.
class PadHintsNotifier extends Notifier<bool> {
  static const _key = 'pref:pad_hints';

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

final padHintsProvider = NotifierProvider<PadHintsNotifier, bool>(
  PadHintsNotifier.new,
);

/// Whether the pencil drawings on the table are shown (default on).
class ShowDrawingsNotifier extends Notifier<bool> {
  static const _key = 'pref:show_drawings';

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

final showDrawingsProvider = NotifierProvider<ShowDrawingsNotifier, bool>(
  ShowDrawingsNotifier.new,
);

/// Whether win streaks (the fire ring around a seat running hot) are
/// drawn, on every seat including the own one (default on).
class ShowHeatNotifier extends Notifier<bool> {
  static const _key = 'pref:show_heat';

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

final showHeatProvider = NotifierProvider<ShowHeatNotifier, bool>(
  ShowHeatNotifier.new,
);

/// Showdown spotlight: lift and highlight each revealed hand's best five
/// with its name in the middle of the table (default on).
class ShowdownSpotlightNotifier extends Notifier<bool> {
  static const _key = 'pref:showdown_spotlight';

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

final showdownSpotlightProvider =
    NotifierProvider<ShowdownSpotlightNotifier, bool>(
      ShowdownSpotlightNotifier.new,
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

/// Where the viewer's "Your hand: …" line is shown: nowhere, on the felt
/// under the community cards, or below the table in the action bar.
enum HandLinePlacement { off, board, bottom }

class HandLineNotifier extends Notifier<HandLinePlacement> {
  static const _key = 'pref:hand_line';

  @override
  HandLinePlacement build() {
    SharedPreferences.getInstance().then((p) {
      final v = p.getString(_key);
      for (final o in HandLinePlacement.values) {
        if (o.name == v) state = o;
      }
    }).ignore();
    // Below the table by default, where it never covers the board.
    return HandLinePlacement.bottom;
  }

  void set(HandLinePlacement value) {
    state = value;
    SharedPreferences.getInstance()
        .then((p) => p.setString(_key, value.name))
        .ignore();
  }

  void next() {
    const all = HandLinePlacement.values;
    set(all[(all.indexOf(state) + 1) % all.length]);
  }
}

final handLineProvider = NotifierProvider<HandLineNotifier, HandLinePlacement>(
  HandLineNotifier.new,
);

/// Your own five, ringed in teal on the felt: the board cards and hole
/// cards that make what you are holding right now. The quickest way to see
/// that a card does not play — and the quickest way to learn why. It steps
/// aside while a pot is being presented so that the winner's gold never
/// competes with it.
///
/// Off by default, like the pot odds: the table has always named the hand
/// and left it at that, and a player who wants more than that is asked in
/// so many words when they join ([HelpLevel]).
class HandHighlightNotifier extends Notifier<bool> {
  static const _key = 'pref:hand_highlight';

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

final handHighlightProvider = NotifierProvider<HandHighlightNotifier, bool>(
  HandHighlightNotifier.new,
);

/// Pot odds over the action buttons: what the call costs, what it stands to
/// win, and how often it has to be good to be worth it. Arithmetic on
/// numbers everyone at the table can already see, so it tells nobody
/// anything about anybody's cards; it only saves doing it in your head.
/// Off until a player asks for it ([HelpLevel]).
class PotOddsNotifier extends Notifier<bool> {
  static const _key = 'pref:pot_odds';

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

final potOddsProvider = NotifierProvider<PotOddsNotifier, bool>(
  PotOddsNotifier.new,
);

/// The board read back in words under your hand: what it threatens for
/// anyone, and what you can still hit. The half a percentage cannot carry
/// — and deliberately even-handed, because a board nobody can call on is
/// also a board worth betting. On from the level that shows which cards
/// play, since both are about reading the board.
class BoardNotesNotifier extends Notifier<bool> {
  static const _key = 'pref:board_notes';

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

final boardNotesProvider = NotifierProvider<BoardNotesNotifier, bool>(
  BoardNotesNotifier.new,
);

/// The strategy's line on your turn, asked of the server: how often the
/// hand wins, what the price asks for, and what it would do. The strongest
/// help there is — it answers the question instead of teaching it — so it
/// is the last thing any level turns on, the host allows it per table, and
/// the instance can refuse it outright. Off until asked for.
class AdviceNotifier extends Notifier<bool> {
  static const _key = 'pref:advice';

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

final adviceProvider = NotifierProvider<AdviceNotifier, bool>(
  AdviceNotifier.new,
);

/// How much help a player wants at the table. The levels are cumulative,
/// and each one is nothing more than a preset of the three switches below
/// it — [handLineProvider], [handHighlightProvider] and [potOddsProvider] —
/// so the level is never a second source of truth that can drift from what
/// the table actually shows. A player who then changes one switch lands on
/// [HelpLevel.custom], which is a reading of the switches and not a setting
/// of its own.
enum HelpLevel {
  /// Nothing: the table says only what a table says.
  none,

  /// The name of your hand, and the hand rankings to put it in context.
  /// This is what Showdown has always done, and the default.
  hand,

  /// Also the cards that make it, ringed on the felt.
  cards,

  /// Also what a call costs against the pot it would win.
  full,

  /// The switches do not match any level; nothing sets this.
  custom,
}

/// Reads the three switches as a level.
/// The percentages are not part of a level: they are an extra for whoever
/// wants the arithmetic, and turning them on should not make a player's
/// answer read as "your own mix". Only the level that turns everything off
/// takes them with it.
HelpLevel helpLevelOf({
  required HandLinePlacement line,
  required bool highlight,
  required bool notes,
  required bool potOdds,
  required bool advice,
}) {
  final named = line != HandLinePlacement.off;
  return switch ((named, highlight, notes, advice)) {
    (false, false, false, false) => potOdds ? HelpLevel.custom : HelpLevel.none,
    (true, false, false, false) => HelpLevel.hand,
    (true, true, true, false) => HelpLevel.cards,
    (true, true, true, true) => HelpLevel.full,
    _ => HelpLevel.custom,
  };
}

/// The level as the three switches, so picking one writes all of them.
/// [HelpLevel.custom] is not a preset and changes nothing.
extension HelpLevelPreset on HelpLevel {
  bool get showsHandLine => this != HelpLevel.none && this != HelpLevel.custom;
  bool get showsHighlight => this == HelpLevel.cards || this == HelpLevel.full;
  bool get showsNotes => showsHighlight;
  bool get showsAdvice => this == HelpLevel.full;
}

/// The advice needs the host's yes and the instance's as well as the
/// player's; the table setting is read where the snapshot is, so this is
/// the player's switch and the instance's. Everything else in the help is
/// the player's own cards read back to them and answers to nobody.
final shownAdviceProvider = Provider<bool>(
  (ref) => ref.watch(adviceAllowedProvider) && ref.watch(adviceProvider),
);

/// The percentages are the working behind the advice, so they follow the
/// same permission. Without this, switching the advice off at the server
/// would *reveal* the bare price line to anyone with the numbers on —
/// quieting the table by taking away its words and leaving its sums.
final shownPotOddsProvider = Provider<bool>(
  (ref) => ref.watch(adviceAllowedProvider) && ref.watch(potOddsProvider),
);

/// Whether this instance allows a recommendation at all. A plain bool, so
/// widgets never deal with a loading state: until the server answers it is
/// allowed, and an instance that refuses simply never answers the ask.
final adviceAllowedProvider = Provider<bool>(
  (ref) => ref.watch(playerAdviceEnabledProvider).value ?? true,
);

/// Applies a level by writing the switches it stands for. The one place
/// that knows what each level means in practice, so the join form and the
/// settings tab cannot drift apart. [HelpLevel.custom] is a reading, not a
/// choice, and does nothing.
void applyHelpLevel(WidgetRef ref, HelpLevel level) {
  if (level == HelpLevel.custom) return;
  final line = ref.read(handLineProvider);
  ref
      .read(handLineProvider.notifier)
      .set(
        !level.showsHandLine
            ? HandLinePlacement.off
            // Whoever had the line somewhere keeps it there.
            : line == HandLinePlacement.off
            ? HandLinePlacement.bottom
            : line,
      );
  ref.read(handHighlightProvider.notifier).set(level.showsHighlight);
  ref.read(boardNotesProvider.notifier).set(level.showsNotes);
  // The percentages stay where the player left them, except at the level
  // that means "tell me nothing".
  if (level == HelpLevel.none) {
    ref.read(potOddsProvider.notifier).set(false);
  }
  ref.read(adviceProvider.notifier).set(level.showsAdvice);
}

/// Whether the player has been asked how much help they want. The join
/// form asks once and never again; changing it later is a settings job.
class HelpAskedNotifier extends Notifier<bool> {
  static const _key = 'pref:help_asked';

  @override
  bool build() {
    SharedPreferences.getInstance().then((p) {
      final v = p.getBool(_key);
      if (v != null) state = v;
    }).ignore();
    return false;
  }

  void mark() {
    state = true;
    SharedPreferences.getInstance().then((p) => p.setBool(_key, true)).ignore();
  }
}

final helpAskedProvider = NotifierProvider<HelpAskedNotifier, bool>(
  HelpAskedNotifier.new,
);
