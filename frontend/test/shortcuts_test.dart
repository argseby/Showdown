import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:showdown/features/table/focus_utils.dart';
import 'package:showdown/features/table/shortcuts.dart';

import 'test_helpers.dart';

KeyDownEvent down(LogicalKeyboardKey key, {String? character}) => KeyDownEvent(
  physicalKey: PhysicalKeyboardKey.keyA,
  logicalKey: key,
  timeStamp: Duration.zero,
  character: character,
);

void main() {
  test('every action has exactly one primary binding', () {
    for (final a in ShortcutAction.values) {
      expect(
        shortcutBindings.where((b) => b.action == a).length,
        1,
        reason: a.name,
      );
    }
    expect(shortcutLabel(ShortcutAction.fold), 'F');
    expect(shortcutLabel(ShortcutAction.amountUpBig), 'Shift+Up');
  });

  test('keys map to actions and key-up events are ignored', () {
    expect(
      shortcutFor(down(LogicalKeyboardKey.keyF), textFieldFocused: false),
      ShortcutAction.fold,
    );
    expect(
      shortcutFor(down(LogicalKeyboardKey.keyC), textFieldFocused: false),
      ShortcutAction.checkCall,
    );
    expect(
      shortcutFor(down(LogicalKeyboardKey.keyR), textFieldFocused: false),
      ShortcutAction.openRaise,
    );
    expect(
      shortcutFor(down(LogicalKeyboardKey.keyA), textFieldFocused: false),
      ShortcutAction.selectAllIn,
    );
    expect(
      shortcutFor(down(LogicalKeyboardKey.digit2), textFieldFocused: false),
      ShortcutAction.preset2,
    );
    expect(
      shortcutFor(down(LogicalKeyboardKey.arrowUp), textFieldFocused: false),
      ShortcutAction.amountUp,
    );
    expect(
      shortcutFor(down(LogicalKeyboardKey.enter), textFieldFocused: false),
      ShortcutAction.confirm,
    );
    expect(
      shortcutFor(
        down(LogicalKeyboardKey.numpadEnter),
        textFieldFocused: false,
      ),
      ShortcutAction.confirm,
    );
    expect(
      shortcutFor(down(LogicalKeyboardKey.keyT), textFieldFocused: false),
      ShortcutAction.focusChat,
    );
    expect(
      shortcutFor(down(LogicalKeyboardKey.keyL), textFieldFocused: false),
      ShortcutAction.toggleLog,
    );
    expect(
      shortcutFor(down(LogicalKeyboardKey.keyB), textFieldFocused: false),
      ShortcutAction.toggleLeaderboard,
    );
    expect(
      shortcutFor(down(LogicalKeyboardKey.keyM), textFieldFocused: false),
      ShortcutAction.toggleSound,
    );
    expect(
      shortcutFor(
        down(LogicalKeyboardKey.slash, character: '?'),
        textFieldFocused: false,
      ),
      ShortcutAction.showHelp,
    );
    expect(
      shortcutFor(down(LogicalKeyboardKey.keyZ), textFieldFocused: false),
      isNull,
    );
    const up = KeyUpEvent(
      physicalKey: PhysicalKeyboardKey.keyF,
      logicalKey: LogicalKeyboardKey.keyF,
      timeStamp: Duration.zero,
    );
    expect(shortcutFor(up, textFieldFocused: false), isNull);
  });

  test('shortcuts are suppressed while typing, except Escape', () {
    expect(
      shortcutFor(down(LogicalKeyboardKey.keyF), textFieldFocused: true),
      isNull,
    );
    expect(
      shortcutFor(down(LogicalKeyboardKey.enter), textFieldFocused: true),
      isNull,
    );
    expect(
      shortcutFor(down(LogicalKeyboardKey.escape), textFieldFocused: true),
      ShortcutAction.cancel,
    );
  });

  testWidgets('a focused text field is detected and Escape releases it', (
    tester,
  ) async {
    final node = FocusNode();
    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            TextField(focusNode: node, key: const Key('tf')),
            const Text('x'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(isTextFieldFocused(), isFalse);
    await tester.tap(find.byKey(const Key('tf')));
    await tester.pumpAndSettle();
    expect(isTextFieldFocused(), isTrue);
    // Keys typed into the field must not fire shortcuts.
    expect(
      shortcutFor(
        down(LogicalKeyboardKey.keyF),
        textFieldFocused: isTextFieldFocused(),
      ),
      isNull,
    );
    unfocusTextField();
    await tester.pumpAndSettle();
    expect(isTextFieldFocused(), isFalse);
    node.dispose();
  });
}
