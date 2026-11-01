import 'dart:math' as math;

import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../features/account/stats_parts.dart';
import '../../../shared/playing_card.dart';

/// The ten hands of poker, best first, with an example of each — and the
/// one the viewer is holding marked, which is the whole reason it opens
/// from the hand line. Beginners lose hands to not knowing that a flush
/// beats a straight; a list they can call up mid-hand is the cheapest
/// possible fix.
Future<void> showHandRankingsDialog(
  BuildContext context, {
  int? category,
  bool royal = false,
  String? description,
  bool fourColor = false,
}) => showOverlay<void>(
  context,
  const DialogConfiguration(),
  builder: (context) => HandRankingsDialog(
    category: category,
    royal: royal,
    description: description,
    fourColor: fourColor,
  ),
).future;

/// One row of the rankings: the category the server numbers it with, and
/// five cards that show what it looks like.
typedef _Rank = (int category, bool royal, List<String> example);

/// Best first. The royal flush is the straight flush to the ace, which is
/// why it shares its category and is told apart by the flag.
const _ranks = <_Rank>[
  (8, true, ['As', 'Ks', 'Qs', 'Js', 'Ts']),
  (8, false, ['9h', '8h', '7h', '6h', '5h']),
  (7, false, ['Qc', 'Qd', 'Qh', 'Qs', '4d']),
  (6, false, ['Jc', 'Jd', 'Jh', '8c', '8s']),
  (5, false, ['Ad', 'Jd', '9d', '6d', '3d']),
  (4, false, ['9c', '8d', '7h', '6s', '5c']),
  (3, false, ['7c', '7d', '7h', 'Kc', '2s']),
  (2, false, ['Kc', 'Kd', '6h', '6s', '9c']),
  (1, false, ['Tc', 'Td', 'As', '8h', '4d']),
  (0, false, ['Ac', 'Jd', '9h', '6s', '3c']),
];

class HandRankingsDialog extends StatelessWidget {
  const HandRankingsDialog({
    super.key,
    this.category,
    this.royal = false,
    this.description,
    this.fourColor = false,
  });

  /// The viewer's own hand (0 high card .. 8 straight flush), or null when
  /// there is no hand to mark — between hands, for a spectator, and on an
  /// instance that serves no player help.
  final int? category;
  final bool royal;

  /// The hand in words, shown against the marked row.
  final String? description;
  final bool fourColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final media = MediaQuery.sizeOf(context);
    final width = math.min(420.0, media.width - 40);
    // Narrow phones: the five example cards shrink before the name does.
    final cardWidth = width < 360 ? 18.0 : 22.0;

    return AlertDialog(
      title: Text(l10n.handRankingsTitle),
      content: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.handRankingsIntro).muted().small(),
            const Gap(10),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: math.max(220.0, media.height * 0.5),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (cat, isRoyal, example) in _ranks)
                      _Row(
                        name: handClassName(l10n, cat, royal: isRoyal),
                        example: example,
                        cardWidth: cardWidth,
                        fourColor: fourColor,
                        // A royal flush marks the royal row only, and any
                        // other straight flush the row below it.
                        mine: category == cat && royal == isRoyal,
                        description: description,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        PrimaryButton(
          key: const Key('hand-rankings-close'),
          onPressed: () => closeOverlay<void>(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.name,
    required this.example,
    required this.cardWidth,
    required this.fourColor,
    required this.mine,
    required this.description,
  });

  final String name;
  final List<String> example;
  final double cardWidth;
  final bool fourColor;
  final bool mine;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Container(
      key: mine ? const Key('rankings-mine') : null,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        // The viewer's own row wears the same teal as the ring on the
        // felt, so the two read as one answer to one question.
        color: mine ? handRing.withValues(alpha: 0.12) : null,
        border: Border.all(
          color: mine
              ? handRing
              : theme.colorScheme.border.withValues(alpha: 0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name).small().semiBold(),
                if (mine) ...[
                  const Gap(2),
                  Text(
                    description == null || description!.isEmpty
                        ? l10n.handRankingsYours
                        : l10n.handRankingsYoursNamed(description!),
                    style: const TextStyle(fontSize: 11, color: handRing),
                  ),
                ],
              ],
            ),
          ),
          const Gap(8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final card in example)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: PlayingCardWidget(
                    card: card,
                    width: cardWidth,
                    fourColor: fourColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
