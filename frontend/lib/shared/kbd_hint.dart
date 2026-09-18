import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../app/preferences.dart';
import '../core/gamepad/gamepad.dart';

/// A small keycap label used as a shortcut hint on buttons and in the
/// shortcuts overlay. With a controller connected the [pad] button shows
/// instead (on any screen size: a pad on a phone or TV is a real setup).
class KbdHint extends ConsumerWidget {
  const KbdHint(this.label, {super.key, this.pad, this.leadingGap = 0});

  final String label;

  /// The controller button for the same action, if any.
  final String? pad;

  /// Space before the cap, only taken when the cap is shown.
  final double leadingGap;

  /// Below this width the keyboard hints are dropped: phones and tablets
  /// have no keyboard, and the buttons need the room.
  static const minWidth = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padOn = ref.watch(gamepadProvider) && ref.watch(padHintsProvider);
    final theme = Theme.of(context);
    final String text;
    final bool round;
    // The pad button replaces the key; a key without a pad button stays
    // (the help overlay lists keyboard-only actions too).
    if (padOn && pad != null) {
      text = pad!;
      round = true;
    } else if (label.isNotEmpty &&
        MediaQuery.sizeOf(context).width >= minWidth) {
      text = label;
      round = false;
    } else {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(left: leadingGap),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: round ? 6 : 5, vertical: 1),
        decoration: BoxDecoration(
          color: theme.colorScheme.muted,
          borderRadius: BorderRadius.circular(round ? 999 : 4),
          border: Border.all(color: theme.colorScheme.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'GeistMono',
            fontWeight: round ? FontWeight.w700 : null,
            color: theme.colorScheme.mutedForeground,
          ),
        ),
      ),
    );
  }
}
