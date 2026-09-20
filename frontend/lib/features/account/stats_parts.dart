import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/account.dart';
import '../../core/formatting.dart';
import '../../shared/pot_colors.dart';

/// The parts a record is drawn from: the groups, rows and meters of the
/// statistics page, and the two cards that show a hand and a milestone.
/// Your own page and a friend's are the same page with different amounts
/// of it, so they are built from the same pieces.

/// The name of a poker category as the server numbers them (0 high card ..
/// 8 straight flush), with the royal flush apart.
String handClassName(
  AppLocalizations l10n,
  int category, {
  bool royal = false,
}) {
  if (royal) return l10n.handRoyalFlush;
  return switch (category) {
    8 => l10n.handStraightFlush,
    7 => l10n.handFourOfAKind,
    6 => l10n.handFullHouse,
    5 => l10n.handFlush,
    4 => l10n.handStraight,
    3 => l10n.handThreeOfAKind,
    2 => l10n.handTwoPair,
    1 => l10n.handPair,
    _ => l10n.handHighCard,
  };
}

/// The name of a milestone, by the id the server sends.
String achievementTitle(AppLocalizations l10n, String id) => switch (id) {
  'royal_flush' => l10n.achRoyalFlushTitle,
  'straight_flush' => l10n.achStraightFlushTitle,
  'quads' => l10n.achQuadsTitle,
  'full_house' => l10n.achFullHouseTitle,
  'big_pot' => l10n.achBigPotTitle,
  'all_in_win' => l10n.achAllInWinTitle,
  'hands_100' => l10n.achHands100Title,
  'hands_1000' => l10n.achHands1000Title,
  'bluffs_25' => l10n.achBluffs25Title,
  'round_win' => l10n.achRoundWinTitle,
  'podium_3' => l10n.achPodium3Title,
  'tournament_win' => l10n.achTournamentWinTitle,
  _ => id,
};

/// What it takes to earn it.
String achievementBody(AppLocalizations l10n, String id) => switch (id) {
  'royal_flush' => l10n.achRoyalFlushBody,
  'straight_flush' => l10n.achStraightFlushBody,
  'quads' => l10n.achQuadsBody,
  'full_house' => l10n.achFullHouseBody,
  'big_pot' => l10n.achBigPotBody,
  'all_in_win' => l10n.achAllInWinBody,
  'hands_100' => l10n.achHands100Body,
  'hands_1000' => l10n.achHands1000Body,
  'bluffs_25' => l10n.achBluffs25Body,
  'round_win' => l10n.achRoundWinBody,
  'podium_3' => l10n.achPodium3Body,
  'tournament_win' => l10n.achTournamentWinBody,
  _ => '',
};

/// The pages of the record. Money first: everything a player asked
/// for in chips is in chips, and the big-blind figures sit next to their
/// explanation instead of leading the page.
/// The chip colour of a result: gold for a win, the warning colour for a
/// loss, plain text for a player who is exactly even.
Color? moneyColor(BuildContext context, num v) => v == 0
    ? null
    : v > 0
    ? potGold
    : Theme.of(context).colorScheme.destructive;

/// The headline of a record: what somebody is up or down, in chips, with
/// a line under it saying over how much play.
class NetHero extends StatelessWidget {
  const NetHero({super.key, required this.net, required this.caption});

  final int net;
  final String caption;

  @override
  Widget build(BuildContext context) => Card(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.statsNet.toUpperCase()).muted().xSmall().semiBold(),
        const Gap(2),
        Text(
          signedChips(context, net),
          key: const Key('stats-net'),
          style: TextStyle(
            fontFamily: 'GeistMono',
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: moneyColor(context, net),
          ),
        ),
        const Gap(2),
        Text(caption).muted().small(),
      ],
    ),
  );
}

/// A group of figures under an icon and a heading.
class StatsGroup extends StatelessWidget {
  const StatsGroup({
    super.key,
    required this.icon,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.mutedForeground;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(icon, size: 12, color: muted),
                const Gap(6),
                Text(title.toUpperCase()).muted().xSmall().semiBold(),
              ],
            ),
          ),
          ...rows,
        ],
      ),
    );
  }
}

/// One label and its figure. [hint] goes under the label in small print,
/// for the rows that would otherwise need explaining.
class StatsRow extends StatelessWidget {
  const StatsRow(this.label, this.value, {super.key, this.hint, this.color});

  final String label;
  final String value;
  final String? hint;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label).muted().small(),
              if (hint != null) Text(hint!).muted().xSmall(),
            ],
          ),
        ),
        const Gap(8),
        Text(
          value,
          style: TextStyle(fontFamily: 'GeistMono', color: color),
        ),
      ],
    ),
  );
}

/// A share of the hands, told as a number and as a bar.
class StatsMeter extends StatelessWidget {
  const StatsMeter(
    this.label,
    this.value,
    this.fraction, {
    super.key,
    this.color,
  });

  final String label;
  final String value;
  final double fraction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(label).muted().small()),
              const Gap(8),
              Text(value, style: const TextStyle(fontFamily: 'GeistMono')),
            ],
          ),
          const Gap(5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 5,
              color: theme.colorScheme.muted,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction.clamp(0, 1),
                child: Container(color: color ?? theme.colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String chipsText(BuildContext context, int v) =>
    formatChips(v, Localizations.localeOf(context).toString());

String signedChips(BuildContext context, int v) =>
    (v > 0 ? '+' : '') + chipsText(context, v);

String bbText(double v) => '${v > 0 ? '+' : ''}${v.toStringAsFixed(1)} bb';

String percentText(double v) => '${v.toStringAsFixed(0)} %';

/// One kept hand: what it was, the five cards, where it happened and what
/// it paid.
class HandCard extends StatelessWidget {
  const HandCard(this.h, {super.key});

  final HandHighlight h;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);
    final name = h.description.isNotEmpty
        ? h.description
        : handClassName(l10n, h.category, royal: h.royal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                      ).small(),
                    ),
                    const Gap(6),
                    Text(
                      h.shown ? l10n.statsShownAtTable : l10n.statsMucked,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
                Text(
                  prettyCards(h.cards),
                  style: const TextStyle(fontFamily: 'GeistMono', fontSize: 12),
                ),
                Text(
                  '${l10n.statsHandAt(h.tableName, '${h.handNumber}')} · '
                  '${formatDate(h.endedAt, locale)}',
                ).muted().xSmall(),
              ],
            ),
          ),
          const Gap(8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                signedChips(context, h.net),
                style: TextStyle(
                  fontFamily: 'GeistMono',
                  color: moneyColor(context, h.net),
                ),
              ),
              if (h.won > 0)
                Text('${h.wonBB.toStringAsFixed(1)} bb').muted().xSmall(),
            ],
          ),
        ],
      ),
    );
  }
}

class AwardRow extends StatelessWidget {
  const AwardRow(this.a, {required this.earned, super.key});

  final Achievement a;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            earned ? LucideIcons.badgeCheck : LucideIcons.lock,
            size: 15,
            color: earned ? potGold : theme.colorScheme.mutedForeground,
          ),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(achievementTitle(l10n, a.id)).small(),
                Text(achievementBody(l10n, a.id)).muted().xSmall(),
              ],
            ),
          ),
          const Gap(8),
          if (earned)
            Text(formatDate(a.earnedAt, locale)).muted().xSmall()
          else if (a.goal > 0)
            Text(l10n.statsProgressOf('${a.progress}', '${a.goal}'))
                .muted()
                .xSmall(),
        ],
      ),
    );
  }
}
