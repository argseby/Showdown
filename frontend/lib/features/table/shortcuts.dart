import 'package:flutter/services.dart';

/// Every keyboard shortcut of the table screen (docs §10.3). This file is the
/// single source of truth: the action bar hints and the `?` overlay read from
/// [shortcutBindings].
enum ShortcutAction {
  fold,
  checkCall,
  openRaise,
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

/// A binding: the key plus whether Shift must be held.
class ShortcutBinding {
  const ShortcutBinding(
    this.action,
    this.key, {
    this.shift = false,
    this.label,
  });

  final ShortcutAction action;
  final LogicalKeyboardKey key;
  final bool shift;

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
