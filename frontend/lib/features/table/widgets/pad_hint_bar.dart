import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../core/gamepad/gamepad.dart';
import '../../../core/gamepad/pad_section.dart';
import '../../../shared/kbd_hint.dart';

/// The strip under the action bar (and at the foot of the panel sheet on
/// phones) while a controller is connected: where the cursor is (action
/// bar, table, side panel and its tab, a dialog) and what the buttons do
/// there. Console games do the same at the bottom of the screen, so
/// players know what A and B mean right now. Nothing without a pad.
class PadHintBar extends ConsumerWidget {
  const PadHintBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(gamepadProvider)) return const SizedBox.shrink();
    final cursor = ref.watch(padCursorProvider);
    if (cursor.where.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      key: const Key('pad-hint'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: theme.colorScheme.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(
              LucideIcons.gamepad2,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const Gap(6),
            Text(cursor.where, key: const Key('pad-where')).semiBold().small(),
            const Gap(14),
            for (final (buttons, text) in cursor.legend) ...[
              for (final b in buttons.split(' '))
                KbdHint('', pad: b, leadingGap: 2),
              const Gap(4),
              Text(text).muted().small(),
              const Gap(12),
            ],
          ],
        ),
      ),
    );
  }
}
