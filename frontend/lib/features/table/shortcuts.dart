import 'package:flutter/services.dart';

import '../../core/gamepad/gamepad.dart';

/// Every keyboard shortcut of the table screen (docs §10.3). This file is the
/// single source of truth: the action bar hints and the `?` overlay read from
/// [shortcutBindings].
enum ShortcutAction {
  fold,
  checkCall,
  openRaise,
  showFirst,
  showSecond,
  showBoth,
  rabbitHunt,
  preCheckFold,
  preCallAny,
  sitOut,
  rebuy,
  focusAmount,
  selectAllIn,
  preset1,
  preset2,
  preset3,
  preset4,
  amountUp,
  amountDown,
  amountUpBig,
  amountDownBig,
  confirm,
  cancel,
  focusChat,
  toggleLog,
  toggleLeaderboard,
  toggleSound,
  showHelp,
}

/// How long a hold shortcut must be pressed before it fires. Its key cap
/// fills up over the same time, so the wait is visible rather than a key
/// that seems not to work.
const shortcutHoldDuration = Duration(milliseconds: 600);

/// A binding: the key plus whether Shift must be held.
class ShortcutBinding {
  const ShortcutBinding(
    this.action,
    this.key, {
    this.shift = false,
    this.label,
    this.hold = false,
  });

  final ShortcutAction action;
  final LogicalKeyboardKey key;
  final bool shift;

  /// The key must be held down for [shortcutHoldDuration]: these arm or
  /// undo something for the whole hand and must not go off by a brush of
  /// the keyboard.
  final bool hold;

  /// Display label; defaults to the key label.
  final String? label;

  String get displayLabel {
    final base = label ?? key.keyLabel;
    return shift ? 'Shift+$base' : base;
  }
}

/// The keyboard map. Order matters for the help overlay.
const List<ShortcutBinding> shortcutBindings = [
  ShortcutBinding(ShortcutAction.fold, LogicalKeyboardKey.keyF, label: 'F'),
  ShortcutBinding(
    ShortcutAction.checkCall,
    LogicalKeyboardKey.keyC,
    label: 'C',
  ),
  ShortcutBinding(
    ShortcutAction.openRaise,
    LogicalKeyboardKey.keyR,
    label: 'R',
  ),
  ShortcutBinding(
    ShortcutAction.focusAmount,
    LogicalKeyboardKey.keyN,
    label: 'N',
  ),
  // The hand is over for the viewer: show a card (left or right, as they
  // lie), show both, or look at the rest of the board.
  ShortcutBinding(
    ShortcutAction.showFirst,
    LogicalKeyboardKey.arrowLeft,
    label: 'Left',
  ),
  ShortcutBinding(
    ShortcutAction.showSecond,
    LogicalKeyboardKey.arrowRight,
    label: 'Right',
  ),
  ShortcutBinding(ShortcutAction.showBoth, LogicalKeyboardKey.keyS, label: 'S'),
  ShortcutBinding(
    ShortcutAction.rabbitHunt,
    LogicalKeyboardKey.keyH,
    label: 'H',
  ),
  // Held, not tapped: these stand for the rest of the hand (or cost chips).
  ShortcutBinding(
    ShortcutAction.preCheckFold,
    LogicalKeyboardKey.keyF,
    shift: true,
    label: 'F',
    hold: true,
  ),
  ShortcutBinding(
    ShortcutAction.preCallAny,
    LogicalKeyboardKey.keyC,
    shift: true,
    label: 'C',
    hold: true,
  ),
  ShortcutBinding(
    ShortcutAction.sitOut,
    LogicalKeyboardKey.keyO,
    label: 'O',
    hold: true,
  ),
  ShortcutBinding(
    ShortcutAction.rebuy,
    LogicalKeyboardKey.keyU,
    label: 'U',
    hold: true,
  ),
  ShortcutBinding(
    ShortcutAction.selectAllIn,
    LogicalKeyboardKey.keyA,
    label: 'A',
  ),
  ShortcutBinding(
    ShortcutAction.preset1,
    LogicalKeyboardKey.digit1,
    label: '1',
  ),
  ShortcutBinding(
    ShortcutAction.preset2,
    LogicalKeyboardKey.digit2,
    label: '2',
  ),
  ShortcutBinding(
    ShortcutAction.preset3,
    LogicalKeyboardKey.digit3,
    label: '3',
  ),
  ShortcutBinding(
    ShortcutAction.preset4,
    LogicalKeyboardKey.digit4,
    label: '4',
  ),
  ShortcutBinding(
    ShortcutAction.amountUp,
    LogicalKeyboardKey.arrowUp,
    label: 'Up',
  ),
  ShortcutBinding(
    ShortcutAction.amountDown,
    LogicalKeyboardKey.arrowDown,
    label: 'Down',
  ),
  ShortcutBinding(
    ShortcutAction.amountUpBig,
    LogicalKeyboardKey.arrowUp,
    shift: true,
    label: 'Up',
  ),
  ShortcutBinding(
    ShortcutAction.amountDownBig,
    LogicalKeyboardKey.arrowDown,
    shift: true,
    label: 'Down',
  ),
  ShortcutBinding(
    ShortcutAction.confirm,
    LogicalKeyboardKey.enter,
    label: 'Enter',
  ),
  ShortcutBinding(
    ShortcutAction.cancel,
    LogicalKeyboardKey.escape,
    label: 'Esc',
  ),
  ShortcutBinding(
    ShortcutAction.focusChat,
    LogicalKeyboardKey.keyT,
    label: 'T',
  ),
  ShortcutBinding(
    ShortcutAction.toggleLog,
    LogicalKeyboardKey.keyL,
    label: 'L',
  ),
  ShortcutBinding(
    ShortcutAction.toggleLeaderboard,
    LogicalKeyboardKey.keyB,
    label: 'B',
  ),
  ShortcutBinding(
    ShortcutAction.toggleSound,
    LogicalKeyboardKey.keyM,
    label: 'M',
  ),
  ShortcutBinding(
    ShortcutAction.showHelp,
    LogicalKeyboardKey.question,
    label: '?',
  ),
];

/// The primary label for an action (for kbd hints on buttons).
String shortcutLabel(ShortcutAction action) =>
    shortcutBindings.firstWhere((b) => b.action == action).displayLabel;

/// Whether the action's key has to be held down (see [shortcutHoldDuration]).
bool shortcutHolds(ShortcutAction action) =>
    shortcutBindings.any((b) => b.action == action && b.hold);

/// The controller mapping (standard layout). A and LB/RB double up: A
/// confirms while the raise control is open and checks or calls otherwise;
/// LB/RB step the amount by five there and jump between the sections of
/// the screen (action bar, table, side panel) elsewhere. The directions
/// step the amount and cycle the presets (up to all-in) in the raise
/// control and move focus everywhere else, crossing into the next section
/// when the current one has nothing further; LT/RT switch the panel's tabs
/// from anywhere and take the cursor there; Back jumps into the side panel
/// and back out.
const Map<ShortcutAction, PadButton> padBindings = {
  ShortcutAction.fold: PadButton.x,
  ShortcutAction.checkCall: PadButton.a,
  ShortcutAction.openRaise: PadButton.y,
  ShortcutAction.amountUp: PadButton.up,
  ShortcutAction.amountDown: PadButton.down,
  ShortcutAction.amountUpBig: PadButton.rb,
  ShortcutAction.amountDownBig: PadButton.lb,
  ShortcutAction.confirm: PadButton.a,
  ShortcutAction.cancel: PadButton.b,
  ShortcutAction.showHelp: PadButton.start,
};

/// The controller button label for an action, null when it has none.
String? padLabel(ShortcutAction action) => padBindings[action]?.label;

/// Resolves a key event to a shortcut. Returns null for non-shortcut keys,
/// key-up events, or (unless [textFieldFocused] is false) any key while a
/// text field has focus except Escape, which always cancels.
ShortcutAction? shortcutFor(KeyEvent event, {required bool textFieldFocused}) {
  if (event is! KeyDownEvent) return null;
  final key = event.logicalKey;
  if (textFieldFocused) {
    return key == LogicalKeyboardKey.escape ? ShortcutAction.cancel : null;
  }
  final shift = HardwareKeyboard.instance.isShiftPressed;
  // '?' arrives as Shift+/ on most layouts or as the question key itself.
  if (key == LogicalKeyboardKey.question ||
      (key == LogicalKeyboardKey.slash && shift) ||
      event.character == '?') {
    return ShortcutAction.showHelp;
  }
  if (key == LogicalKeyboardKey.numpadEnter) return ShortcutAction.confirm;
  for (final b in shortcutBindings) {
    if (b.key == key && b.shift == shift) return b.action;
  }
  // Shift+letter should still trigger the letter shortcuts.
  for (final b in shortcutBindings) {
    if (b.key == key && !b.shift) return b.action;
  }
  return null;
}
