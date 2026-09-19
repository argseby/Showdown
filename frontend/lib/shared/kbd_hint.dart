import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../app/preferences.dart';
import '../core/gamepad/gamepad.dart';
import '../features/table/shortcuts.dart';

/// A small keycap label used as a shortcut hint on buttons and in the
/// shortcuts overlay. With a controller connected the [pad] button shows
/// instead (on any screen size: a pad on a phone or TV is a real setup).
class KbdHint extends ConsumerWidget {
  const KbdHint(
    this.label, {
    super.key,
    this.pad,
    this.leadingGap = 0,
    this.holding = false,
  });

  final String label;

  /// The controller button for the same action, if any.
  final String? pad;

  /// Space before the cap, only taken when the cap is shown.
  final double leadingGap;

  /// The key is being held down for a hold shortcut: the cap fills up over
  /// [shortcutHoldDuration] so the wait is visible, and empties again when
  /// the key is let go early.
  final bool holding;

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
    final radius = BorderRadius.circular(round ? 999 : 4);
    final cap = Container(
      padding: EdgeInsets.symmetric(horizontal: round ? 6 : 5, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: radius,
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
    );
    return Padding(
      padding: EdgeInsets.only(left: leadingGap),
      child: Stack(
        children: [
          cap,
          Positioned.fill(
            child: ClipRRect(
              borderRadius: radius,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(holding),
                tween: Tween(begin: 0, end: holding ? 1.0 : 0.0),
                duration: holding
                    ? shortcutHoldDuration
                    : const Duration(milliseconds: 120),
                builder: (context, t, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: t,
                  child: ColoredBox(
                    color: theme.colorScheme.primary.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
