import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/preferences.dart';
import '../../../shared/chip_stack.dart';
import '../../../shared/playing_card.dart';

/// A preference that changes the table itself rather than a detail of it,
/// explained where it is switched: what it does, and a small picture of it
/// doing it. The plain rows above are for settings whose name says it all.
class PreferenceCard extends StatelessWidget {
  const PreferenceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.value,
    required this.preview,
    this.onChanged,
    this.trailing,
    this.switchKey,
  });

  final IconData icon;
  final String title;
  final String body;

  /// Whether the setting is on, which is what dims the picture.
  final bool value;

  /// The switch, when the setting is one. A setting with more than two
  /// states passes its own control as [trailing] instead.
  final ValueChanged<bool>? onChanged;
  final Widget? trailing;

  /// A small picture of what the setting does, shown on.
  final Widget preview;
  final Key? switchKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Card(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16),
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title).semiBold().small(),
                      const Gap(2),
                      Text(body).muted().xSmall(),
                    ],
                  ),
                ),
                const Gap(8),
                trailing ??
                    Switch(
                      key: switchKey,
                      value: value,
                      onChanged: onChanged ?? (_) {},
                    ),
              ],
            ),
            const Gap(10),
            // The picture dims when the setting is off, so the switch and
            // what it does are one thing rather than two.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: value ? 1 : 0.35,
              child: SizedBox(height: 46, child: Center(child: preview)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chips on the felt: stacks of them, as they are drawn at a seat. Each
/// stack is laid out in a box of its own height — a chip nudged upwards by
/// a transform would still be laid out where it was, and would climb into
/// the text above.
class ChipStackPreview extends StatelessWidget {
  const ChipStackPreview({super.key});

  /// How much of each chip below stays visible.
  static const _step = 5.0;
  static const _chip = 14.0;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      for (final stack in const [(3, 25), (5, 100), (2, 500)])
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: SizedBox(
            width: _chip,
            height: _chip + (stack.$1 - 1) * _step,
            child: Stack(
              children: [
                for (var i = 0; i < stack.$1; i++)
                  Positioned(
                    left: 0,
                    bottom: i * _step,
                    child: ChipIcon(
                      size: _chip,
                      color: chipAmountColor(stack.$2),
                    ),
                  ),
              ],
            ),
          ),
        ),
    ],
  );
}

/// Fixed seats: the table as it is drawn for everyone, with the viewer's
/// own seat marked wherever it happens to be.
class FixedSeatsPreview extends StatelessWidget {
  const FixedSeatsPreview({super.key, this.fixed = true});

  final bool fixed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget seat(bool you) => Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: you ? theme.colorScheme.primary : theme.colorScheme.muted,
        border: Border.all(
          color: you
              ? theme.colorScheme.primary
              : theme.colorScheme.mutedForeground.withValues(alpha: 0.4),
        ),
      ),
    );
    // Off, the viewer is always at the bottom; on, the seats keep their
    // places and the viewer is wherever they sat down.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [seat(false), seat(fixed), seat(false)],
        ),
        const Gap(4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [seat(false), seat(!fixed), seat(false)],
        ),
      ],
    );
  }
}

/// The spotlight: the hand that won, lit while everything else dims.
class SpotlightPreview extends StatelessWidget {
  const SpotlightPreview({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Opacity(
        opacity: 0.35,
        child: PlayingCardWidget(card: '7c', width: 24),
      ),
      const Gap(3),
      const Opacity(
        opacity: 0.35,
        child: PlayingCardWidget(card: '2d', width: 24),
      ),
      const Gap(8),
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.55),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayingCardWidget(card: 'As', width: 26, highlighted: true),
            Gap(3),
            PlayingCardWidget(card: 'Ah', width: 26, highlighted: true),
          ],
        ),
      ),
    ],
  );
}

/// The deck: the same four aces, in two colours or in four.
class FourColorPreview extends StatelessWidget {
  const FourColorPreview({super.key, required this.fourColor});

  final bool fourColor;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final card in const ['As', 'Ah', 'Ad', 'Ac'])
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: PlayingCardWidget(card: card, width: 24, fourColor: fourColor),
        ),
    ],
  );
}

/// Where the line naming your hand goes: on the felt, under the table, or
/// nowhere.
class HandLinePreview extends StatelessWidget {
  const HandLinePreview({super.key, required this.placement});

  final HandLinePlacement placement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget line() => Container(
      width: 62,
      height: 7,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 104,
          height: 30,
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.muted,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: theme.colorScheme.mutedForeground.withValues(alpha: 0.3),
            ),
          ),
          child: placement == HandLinePlacement.board
              ? line()
              : const SizedBox(height: 7),
        ),
        const Gap(3),
        placement == HandLinePlacement.bottom
            ? line()
            : const SizedBox(height: 7),
      ],
    );
  }
}
