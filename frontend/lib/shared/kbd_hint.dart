import 'package:shadcn_flutter/shadcn_flutter.dart';

/// A small keycap label used as a shortcut hint on buttons and in the
/// shortcuts overlay.
class KbdHint extends StatelessWidget {
  const KbdHint(this.label, {super.key});

  final String label;

  /// Below this width the hints are dropped: phones and tablets have no
  /// keyboard, and the buttons need the room.
  static const minWidth = 900.0;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < minWidth) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'GeistMono',
          color: theme.colorScheme.mutedForeground,
        ),
      ),
    );
  }
}
